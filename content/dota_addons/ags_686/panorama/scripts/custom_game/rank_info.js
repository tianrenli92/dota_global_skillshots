function OpenMyUI() {
         GameEvents.SendCustomGameEventToServer( "myui_open", {} );
}

function ToggleMyUI() {
            $("#myui_panel").SetHasClass("Hidden", !($("#myui_panel").BHasClass("Hidden")));
}
