import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin":"*", "Access-Control-Allow-Headers":"authorization, apikey, content-type", "Access-Control-Allow-Methods":"POST, OPTIONS" };
Deno.serve(async (req) => {
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 const json=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});
 try {
  const token=(req.headers.get("Authorization")||"").replace(/^Bearer\\s+/i,"");
  if(!token) return json({error:"يلزم تسجيل الدخول"},401);
  const url=Deno.env.get("SUPABASE_URL")!, key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin=createClient(url,key);
  const {data:{user},error:userErr}=await admin.auth.getUser(token);
  if(userErr||!user) return json({error:"جلسة الدخول غير صالحة"},401);
  const {data:profile}=await admin.from("customer_profiles").select("role,active").eq("id",user.id).single();
  if(!profile||!profile.active||profile.role!=="admin") return json({error:"غير مصرح"},403);
  const body=await req.json();
  if(body.action==="create"){
   const email=String(body.email||"").trim(), password=String(body.password||""), display_name=String(body.display_name||"").trim();
   if(!email||password.length<6||!display_name) return json({error:"أدخل الاسم والبريد وكلمة مرور من 6 أحرف على الأقل"},400);
   const {data,error}=await admin.auth.admin.createUser({email,password,email_confirm:true,user_metadata:{display_name}});
   if(error) return json({error:error.message},400);
   const {error:profileErr}=await admin.from("customer_profiles").upsert({id:data.user.id,display_name,active:true,role:"customer"});
   if(profileErr){await admin.auth.admin.deleteUser(data.user.id);return json({error:profileErr.message},400);}
   return json({ok:true});
  }
  if(body.action==="update"){
   const id=String(body.user_id||"");
   if(!id||id===user.id) return json({error:"لا يمكنك تعديل حسابك من هذه الشاشة"},400);
   const patch:any={};
   if(typeof body.active==="boolean") patch.active=body.active;
   if(["admin","customer"].includes(body.role)) patch.role=body.role;
   if(!Object.keys(patch).length) return json({error:"لا يوجد تعديل صالح"},400);
   const {error}=await admin.from("customer_profiles").update(patch).eq("id",id);
   if(error) return json({error:error.message},400);
   return json({ok:true});
  }
  return json({error:"عملية غير معروفة"},400);
 } catch(e) { return json({error:String(e)},500); }
});