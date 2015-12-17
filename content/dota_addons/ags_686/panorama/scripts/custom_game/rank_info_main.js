function JsToLua() {
         GameEvents.SendCustomGameEventToServer( "js_to_lua", {num:5, str:"JavaScript"} );
}
  
function LuaToJs() {
         GameEvents.SendCustomGameEventToServer( "lua_to_js", {} );
}

function OnLuaToJs(data) {
         $.Msg(data.str)
}
GameEvents.Subscribe( "on_lua_to_js", OnLuaToJs);