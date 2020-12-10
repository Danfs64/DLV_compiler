package dlvc;

import java.util.HashMap;
import java.util.Map;

public class LuaTable implements LuaType {
    private Map<LuaType, LuaType> map = new HashMap<>();

    public LuaType get(LuaType obj) {
        return map.get(obj);
    }

    public void set(LuaType obj1, LuaType obj2) {
        map.put(obj1, obj2);
    }

    public boolean boolValue() {
        return true;
    }
}
