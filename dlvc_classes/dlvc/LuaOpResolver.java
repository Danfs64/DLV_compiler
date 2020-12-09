package dlvc;

import java.util.Objects;
import java.util.Map;
import java.util.HashMap;
import java.lang.Math;

public class LuaOpResolver {
    /**
     * TODO: Converter string para double
     */
    static public LuaType plus(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number + rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType minus(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number - rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType times(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number * rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType over(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number / rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType pow(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(Math.pow(lhsn.number, rhsn.number));
        }

        return new LuaNil();
    }

    static public LuaType mod(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number % rhsn.number);
        }

        return new LuaNil();
    }

    private class LuaTypePair {
        LuaType type1;
        LuaType type2;

        public LuaTypePair(LuaType t1, LuaType t2) {
            type1 = t1;
            type2 = t2;
        }

        public int hashCode() {
            return Objects.hash(type1, type2);
        }
    }
}
