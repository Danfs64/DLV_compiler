package dlvc;


class LuaString implements LuaType {
    private String luastring;

    @Override
    public int hashCode() {
        return luastring.hashCode();
    }
}
