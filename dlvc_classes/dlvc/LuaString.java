package dlvc;


public class LuaString implements LuaType {
    protected String luastring;

    public LuaString(String s) {
        luastring = s;
    }

    @Override
    public int hashCode() {
        return luastring.hashCode();
    }

    @Override
    public String toString() {
        return luastring;
    }

    public boolean boolValue() {
        return true;
    }
}
