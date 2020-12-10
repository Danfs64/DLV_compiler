package dlvc;

// import java.util.Objects;
// import java.util.Map;
// import java.util.HashMap;
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

    static public LuaType pow(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(Math.pow(lhsn.number, rhsn.number));
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

    static public LuaType iover(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(Math.floor(lhsn.number / rhsn.number));
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

    static public LuaType cat(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaString &&
            rhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                LuaString rhsn = (LuaString) rhs;
                return new LuaString(lhsn.luastring + rhsn.luastring);
        }

        return new LuaNil();
    }

    static public LuaType len(LuaType lhs) {
        if (lhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                return new LuaNumber(lhsn.luastring.length());
        }

        return new LuaNil();
    }

    static public LuaType not(LuaType lhs) {
        return new LuaBool(!lhs.boolValue());
    }

    static public LuaType and(LuaType lhs, LuaType rhs) {
        if (lhs.boolValue()) {
            return rhs;
        } else {
            return lhs;
        }
    }

    static public LuaType or(LuaType lhs, LuaType rhs) {
        if (lhs.boolValue()) {
            return lhs;
        } else {
            return rhs;
        }
    }

    static public LuaType bnot(LuaType lhs) {
        if (lhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                return new LuaNumber(~lhsn.number.intValue());
        }

        return new LuaNil();
    }

    static public LuaType band(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number.intValue() & rhsn.number.intValue());
        }

        return new LuaNil();
    }

    static public LuaType bor(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number.intValue() | rhsn.number.intValue());
        }

        return new LuaNil();
    }

    static public LuaType rshift(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number.intValue() >> rhsn.number.intValue());
        }

        return new LuaNil();
    }

    static public LuaType lshift(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaNumber(lhsn.number.intValue() << rhsn.number.intValue());
        }

        return new LuaNil();
    }

    static public LuaType gt(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaBool(lhsn.number > rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType ge(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaBool(lhsn.number >= rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType lt(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaBool(lhsn.number < rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType le(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaBool(lhsn.number <= rhsn.number);
        }

        return new LuaNil();
    }

    static public LuaType eq(LuaType lhs, LuaType rhs) { 
        if (lhs instanceof LuaString &&
            rhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                LuaString rhsn = (LuaString) rhs;
                return new LuaBool(lhsn.luastring.equals(rhsn.luastring));
        }
        
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaBool(Double.compare(lhsn.number, rhsn.number) == 0);
        }
        
        if (lhs instanceof LuaTable &&
            rhs instanceof LuaTable) {
            return new LuaBool(lhs == rhs);
        }

        return new LuaNil();
    }

    static public LuaType neq(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaString &&
            rhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                LuaString rhsn = (LuaString) rhs;
                return new LuaBool(!lhsn.luastring.equals(rhsn.luastring));
        }
        
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaBool(lhsn.number != rhsn.number);
        }
        
        if (lhs instanceof LuaTable &&
            rhs instanceof LuaTable) {
            return new LuaBool(lhs != rhs);
        }
        
        return new LuaNil();
    }

    /*
    * Versão alternativa de `neq`
    static public LuaType neq(LuaType lhs, LuaType rhs) {
        LuaType igual = eq(lhs, rhs);

        return (igual instanceof LuaNil) ? igual : new LuaBool(!igual.boolValue());
    }
    */

    // private class LuaTypePair {
    //     LuaType type1;
    //     LuaType type2;

    //     public LuaTypePair(LuaType t1, LuaType t2) {
    //         type1 = t1;
    //         type2 = t2;
    //     }

    //     public int hashCode() {
    //         return Objects.hash(type1, type2);
    //     }
    // }
}
