<!---
	Class: Routing
	
	TODO: this whole thing is new and was hacked out - there will be much change so I'm not bothering on comments or
	much documentation at the moment.
	
	Test
--->
<cfcomponent output="false">
	<!--- Pseudo-constructor --->
	<cfscript>
		function reset() {
			variables.instance = {};
			/* An array of all routes */
			variables.instance.routes = [];
			/* A structure of routes keyed by RegEX URI */
			variables.instance.REURIRouteMap = {};
			/* A structure of named routes keyed by name */
			variables.instance.namedRoutes = {};
			/* An array of connected routes */
			variables.instance.connectedRoutes = [];
		
			variables.Pattern = CreateObject("java", "java.util.regex.Pattern");
		
			/* Pre-compile static RegEX to save time */
			variables.instance.NamedArgPattern = variables.Pattern.compile("/?:([^:/$]+)");
			variables.instance.RoutePathPattern = variables.Pattern.compile("(/?):([^:/$]+)");
		} reset();
	</cfscript>
	
	<cffunction name="addNamed" output="false" access="public">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfargument name="parameters" type="struct" required="true" />
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset addRoute(arguments) />
		<cfset addNamedRoute(arguments.name, arguments) />
		<cfset mapRouteByREURI(parseRoutePathToREURI(arguments.path, arguments.parameters), arguments) />
	</cffunction>
	
	<cffunction name="add" output="false" access="public">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="parameters" type="struct" required="true" />
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset addRoute(arguments) />
		<cfset addConnectedRoute(arguments) />
		<cfset mapRouteByREURI(parseRoutePathToREURI(arguments.path, arguments.parameters), arguments) />
	</cffunction>
	
	<cffunction name="findRouteByURI" output="false" access="public">
		<cfargument name="uri" type="string" required="true" />
		<cfset var local = {} />
		<cfloop item="local.thisRoute" collection="#variables.instance.REURIRouteMap#">
			<!--- Ugly check here that will validate a empty URI/Route-Path --->
			<cfif (Len(local.thisRoute) EQ 0 AND Len(arguments.uri) EQ 0)
				OR (Len(local.thisRoute) GT 0 AND REFindNoCase(local.thisRoute, arguments.uri) NEQ 0)>
				<cfset local.routeDetails = variables.instance.REURIRouteMap[local.thisRoute] />
				<!--- Extract "URL" variables from named arguments --->
				<cfset local.NamedArgMatcher = variables.instance.NamedArgPattern.matcher(local.routeDetails.path) />
				<cfset local.ValueMatcher = variables.Pattern.compile("(?i)"&local.thisRoute).matcher(arguments.uri) />
				<cfset local.ValueMatcher.find() />
				<cfset local.i = 1 />
				<!--- Loop over named arguments in path and populate URL variables --->
				<cfloop condition="local.NamedArgMatcher.find()">
					<cfset url[local.NamedArgMatcher.group(1)] = local.ValueMatcher.group(local.i++) />
				</cfloop>
				<cfreturn local.routeDetails />
			</cfif>
		</cfloop>
		<cfreturn false />
	</cffunction>
	
	<cffunction name="findRouteByName" output="false" access="public">
		<cfargument name="name" type="string" required="true" />
		<cfif StructKeyExists(variables.instance.namedRoutes, arguments.name)>
			<cfreturn variables.instance.namedRoutes[arguments.name] />
		</cfif>
		<cfreturn false />
	</cffunction>
	
	<cffunction name="getRoutes" output="false" access="public">
		<cfreturn variables.instance.routes />
	</cffunction>
	
	<cffunction name="getRoutePathArguments" output="false" access="public">
		<cfargument name="path" type="string" required="true" />
		<cfset var local = {} />
		<cfset local.arguments = [] />
		<cfset local.Matcher = variables.instance.NamedArgPattern.matcher(arguments.path) />
		<cfloop condition="local.Matcher.find()">
			<cfset ArrayAppend(local.arguments, local.Matcher.group(1)) />
		</cfloop>
		<cfreturn local.arguments />
	</cffunction>
	
	<!---
		PRIVATE
	--->
	
	<cffunction name="parseRoutePathToREURI" output="false" access="private">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="parameters" type="struct" required="true" />
		<cfset var local = {} />
		<cfset local.newPath = arguments.path />
		<!--- Look for arguments --->
		<cfset local.Matcher = variables.instance.RoutePathPattern.matcher(local.newPath) />
		<!--- Loop over each argument in the path --->
		<cfloop condition="local.Matcher.find()">
			<cfset local.thisNamedArg = local.Matcher.group(2) />
			<!--- Check if we have a validator (regex) for the named argument --->
			<cfif StructKeyExists(arguments.parameters, local.thisNamedArg)>
				<cfset local.newPath = Replace(local.newPath, local.Matcher.group(),
					local.Matcher.group(1) & "(" & arguments.parameters[local.thisNamedArg] & ")") />
			<cfelse>
				<cfset local.newPath = Replace(local.newPath, local.Matcher.group(),
					local.Matcher.group(1) & "([^/]+)") />
			</cfif>
		</cfloop>
		<!--- Leave root route alone --->
		<cfif local.newPath NEQ "">
			<cfset local.newPath = "^" & local.newPath & "/$" />
		</cfif>
		<cfreturn local.newPath />
	</cffunction>
	
	<cffunction name="addRoute" output="false" access="private">
		<cfargument name="route" type="struct" required="true" />
		<cfreturn ArrayAppend(variables.instance.routes, arguments.route) />
	</cffunction>
	
	<cffunction name="mapRouteByREURI" output="false" access="private">
		<cfargument name="REURI" type="string" required="true" />
		<cfargument name="route" type="struct" required="true" />
		<cfreturn StructInsert(variables.instance.REURIRouteMap, arguments.REURI, arguments.route) />
	</cffunction>
	
	<cffunction name="addNamedRoute" output="false" access="private">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="route" type="struct" required="true" />
		<cfreturn StructInsert(variables.instance.namedRoutes, arguments.name, arguments.route) />
	</cffunction>
	
	<cffunction name="addConnectedRoute" output="false" access="private">
		<cfargument name="route" type="struct" required="true" />
		<cfreturn ArrayAppend(variables.instance.connectedRoutes, arguments.route) />
	</cffunction>
</cfcomponent>