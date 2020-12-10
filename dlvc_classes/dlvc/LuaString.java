package dlvc;

import java.util.Objects;

public class LuaString implements LuaType {
    protected String luastring;

    public LuaString(String s) {
        luastring = s;
    }

    @Override
    public int hashCode() {
        return Objects.hash(luastring);
    }

    @Override
    public String toString() {
        return luastring;
    }

    @Override
    public boolean equals(Object o) {
        if (o instanceof LuaString) {
            LuaString ol = (LuaString) o;
            return luastring.equals(ol.luastring);
        }
        return false;
    }

    public Double toNumber() {
        return Double.valueOf(this.luastring);
    }

    public boolean boolValue() {
        return true;
    }
}
