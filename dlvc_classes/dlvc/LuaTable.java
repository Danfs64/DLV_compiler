package dlvc;

import java.util.HashMap;
import java.util.Map;

public class LuaTable implements LuaType {
    private Map<LuaType, LuaType> map = new HashMap<>();

    public static LuaType get(LuaType table, LuaType obj) {
        if (table instanceof LuaTable) {
            LuaTable tmp = (LuaTable) table;
            return tmp.map.get(obj);
        }
        return new LuaNil();
    }

    public void set(LuaType obj1, LuaType obj2) {
        map.put(obj1, obj2);
    }

    public static void put(LuaType table, LuaType obj1, LuaType obj2) {
        if (table instanceof LuaTable) {
            LuaTable tmp = (LuaTable) table;
            tmp.map.put(obj1, obj2);
        }
    }

    public boolean boolValue() {
        return true;
    }
}
