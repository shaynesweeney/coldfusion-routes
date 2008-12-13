<cfscript>
	r = CreateObject("component", "Routing");
	r.reset();
	
	r.addNamed("home", "", $(controller="main", action="index"));
	
	r.addNamed("login", "login", $(controller="user", action="login"));
	r.addNamed("logout", "logout", $(controller="user", action="logout"));
	
	r.addNamed("messages", "messages/:page", $(controller="member", action="messages", page="[a-z]+"));
	
	r.add("dashboard", $(controller="user", action="dashboard"));
	
	$ = function $(){return arguments;}
</cfscript>