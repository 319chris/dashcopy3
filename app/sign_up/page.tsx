"use client"

import { useState } from "react"
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import Link from "next/link";


export default function SignUpPage(){
	const[ email, setEmail ] = useState("");
	const[ password, setPassword ] = useState("");
	const[ submitting, setSubmitting ] = useState<boolean>(false); 
	const[ errorMessage, setErrorMessage ] = useState<string | null>(null);
	const[ noticeMessage, setNoticeMessage] = useState<string | null>(null);

	const supabase = createClient();
	const router = useRouter();

	async function handleSubmit(event: React.FormEvent<HTMLFormElement>){
		event.preventDefault();

		setSubmitting(true);
		setErrorMessage(null);
		setNoticeMessage(null);

		try{
			const{ data, error } = await supabase.auth.signUp({email, password, options:{ emailRedirectTo: `${window.location.origin}/auth/callback`}});

			if(error){
				setErrorMessage(error.message);
				return;
			}

			if(!data.session){
				setNoticeMessage("Account has been created, check your email to verify your account");
				return;
			}
			router.push("/dashboard");
			router.refresh();
		}finally{
			setSubmitting(false)
		}
	}
	return (
		<main style={{ padding: 24, maxWidth: 420 }}>
		  <h1>Create account</h1>

		  <form onSubmit={handleSubmit} style={{ display: "grid", gap: 12 }}>
		    <label>
		      Email
		      <input
		        type="email"
		        value={email}
		        onChange={(event) => setEmail(event.target.value)}
		        disabled={submitting}
		        required
		      />
		    </label>

		    <label>
		      Password
		      <input
		        type="password"
		        value={password}
		        onChange={(event) => setPassword(event.target.value)}
		        disabled={submitting}
		        required
		      />
		    </label>

		    {errorMessage ? <p style={{ color: "crimson" }} role="alert">{errorMessage}</p> : null}
		    {noticeMessage ? <p style={{ color: "seagreen" }}>{noticeMessage}</p> : null}

		    <button type="submit" disabled={submitting}>
		      {submitting ? "Creating account..." : "Create account"}
		    </button>
		  </form>

		  <p>Already have an account? <Link href="/sign_in">Sign in</Link></p>
		</main>
		);
}
