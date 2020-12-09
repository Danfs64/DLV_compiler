package dlvc;

public class LuaBool implements LuaType {
    boolean bool;

    public LuaBool(boolean b) {
        bool = b;
    }

    public boolean boolValue() {
        return bool;
    }

    @Override
    public String toString() {
        return String.valueOf(bool);
    }
}
