import { redirect } from "next/navigation";
import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";


export async function GET(request: NextRequest){
	const code = request.nextUrl.searchParams.get("code");

	if(!code){
		redirect("/sign_in");
	}

	const supabase = await createClient();
	const { error } = await supabase.auth.exchangeCodeForSession(code);
	if(error){
		redirect("/sign_in")
	}

	redirect("/dashboard")


}
