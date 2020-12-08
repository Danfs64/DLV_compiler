package dlvc;

class LuaOpResolver {
    static public LuaType plus(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number + rhsn.number);
            }

        return new LuaNil();
    }
}
