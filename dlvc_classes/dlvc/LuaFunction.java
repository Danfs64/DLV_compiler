package dlvc;

interface LuaFunction extends LuaType {
    public LuaType[] function(LuaType[] args);
}
