package dlvc;

public class LuaNil implements LuaType {
    public boolean boolValue() {
        return false;
    }

    @Override
    public String toString() {
        return "nil";
    }
}
