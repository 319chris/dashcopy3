-- =========================================================
-- 1. companies：这家公司是谁
-- =========================================================
create table public.companies (
  id uuid primary key default gen_random_uuid(),   -- 主键，自动生成 UUID
  name text not null,                              -- 公司显示名，可以重复
  slug text not null unique,                       -- 系统唯一标识，不能重复
  portal_status text not null default 'active'     -- 门户是否开通
    check (portal_status in ('active', 'inactive')),
  created_at timestamptz not null default now()
);

-- =========================================================
-- 2. company_members：这个人属于哪家公司、什么角色
-- =========================================================
create table public.company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null
    references public.companies(id) on delete cascade,  -- 公司删了，成员关系一起删
  user_id uuid not null unique                          -- unique = 一人最多一家公司
    references auth.users(id) on delete cascade,        -- 账号删了，成员关系一起删
  role text not null
    check (role in ('owner', 'member', 'admin')),
  created_at timestamptz not null default now()
);

-- =========================================================
-- 3. company_onboarding：这家公司开通到哪一步、开了哪些产品
-- =========================================================
create table public.company_onboarding (
  company_id uuid primary key                           -- 主键就是 company_id = 一家公司只有一行
    references public.companies(id) on delete cascade,
  onboarding_status text not null default 'in_process'
    check (onboarding_status in ('in_process', 'submitted', 'ready')),
  products text[] not null default '{}'                 -- text 数组，默认空数组
    check (products <@ array['chatbot', 'voice_agent']::text[]),  -- 只能是这两个值的子集
  created_at timestamptz not null default now()
);

-- =========================================================
-- 开启 RLS：从这一刻起，默认谁都读不到（service role 除外）
-- =========================================================
alter table public.companies enable row level security;
alter table public.company_members enable row level security;
alter table public.company_onboarding enable row level security;

-- =========================================================
-- Policy 1：只能看到自己的那一行成员关系
-- 这是另外两条 policy 的"地基"
-- =========================================================
create policy "Members can view their own membership"
on public.company_members
for select
to authenticated                                -- 只针对已登录用户，anon 完全读不到
using ((select auth.uid()) = user_id);

-- =========================================================
-- Policy 2：只能看到自己所在的公司
-- 判断方法：company_members 里存在"我 + 这家公司"的记录
-- =========================================================
create policy "Members can view their company"
on public.companies
for select
to authenticated
using (
  exists (
    select 1
    from public.company_members
    where company_members.company_id = companies.id
      and company_members.user_id = (select auth.uid())
  )
);

-- =========================================================
-- Policy 3：只能看到自己公司的 onboarding
-- =========================================================
create policy "Members can view their company onboarding"
on public.company_onboarding
for select
to authenticated
using (
  exists (
    select 1
    from public.company_members
    where company_members.company_id = company_onboarding.company_id
      and company_members.user_id = (select auth.uid())
  )
);

-- 故意不写 insert / update / delete policy：
-- 用户不能自己建公司、把自己加进公司、或者改自己的开通状态。
-- 这些写操作将来由审批 RPC（第 13 步）在数据库内部完成。