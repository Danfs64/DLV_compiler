package dlvc;

// import java.util.Objects;
// import java.util.Map;
// import java.util.HashMap;
import java.lang.Math;

interface OpInterface {
    Double op_func(Double a, Double b);

    default LuaType calculate(LuaType lhs, LuaType rhs) {
        Double lhsn = null;
        Double rhsn = null;
        
        if (lhs instanceof LuaNumber) {
            lhsn = ((LuaNumber) lhs).number;
        } else if (lhs instanceof LuaString) {
            lhsn = ((LuaString) lhs).toNumber();
        }

        if (rhs instanceof LuaNumber) {
            rhsn = ((LuaNumber) rhs).number;
        } else if (rhs instanceof LuaString) {
            rhsn = ((LuaString) rhs).toNumber();
        }

        if (lhsn == null || rhsn == null) return new LuaNil();
        
        return new LuaNumber(op_func(lhsn, rhsn));
    }
}

public class LuaOpResolver {
    /**
     * TODO: Converter string para double
     */

    static public LuaType plus(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> a + b;
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType minus(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> a - b;
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType times(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> a * b;
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType pow(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> Math.pow(a, b);
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType over(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> a / b;
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType iover(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> Math.floor(a / b);
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType mod(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> a % b;
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType cat(LuaType lhs, LuaType rhs) {
        String lhsn = null;
        String rhsn = null;
        
        if (lhs instanceof LuaNumber) {
            lhsn = String.valueOf(((LuaNumber) lhs).number);
        } else if (lhs instanceof LuaString) {
            lhsn = ((LuaString) lhs).luastring;
        }
        
        if (rhs instanceof LuaNumber) {
            rhsn = String.valueOf(((LuaNumber) rhs).number);
        } else if (rhs instanceof LuaString) {
            rhsn = ((LuaString) lhs).luastring;
        }

        if (lhsn == null || rhsn == null) return new LuaNil();
        
        return new LuaString(lhsn + rhsn);
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
        return lhs.boolValue() ? rhs : lhs;
    }

    static public LuaType or(LuaType lhs, LuaType rhs) {
        return lhs.boolValue() ? lhs : rhs;
    }

    static public LuaType bnot(LuaType lhs) {
        OpInterface op_calculator = (Double a, Double b) -> Double.longBitsToDouble(
            ~ Double.doubleToLongBits(a)
        );
        return op_calculator.calculate(lhs, lhs);
    }

    static public LuaType band(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> Double.longBitsToDouble(
            Double.doubleToLongBits(a) & Double.doubleToLongBits(b)
        );
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType bor(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> Double.longBitsToDouble(
            Double.doubleToLongBits(a) | Double.doubleToLongBits(b)
        );
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType bxor(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> Double.longBitsToDouble(
            Double.doubleToLongBits(a) ^ Double.doubleToLongBits(b)
        );
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType rshift(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> Double.longBitsToDouble(
            Double.doubleToLongBits(a) >> Double.doubleToLongBits(b)
        );
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType lshift(LuaType lhs, LuaType rhs) {
        OpInterface op_calculator = (Double a, Double b) -> Double.longBitsToDouble(
            Double.doubleToLongBits(a) << Double.doubleToLongBits(b)
        );
        return op_calculator.calculate(lhs, rhs);
    }

    static public LuaType gt(LuaType lhs, LuaType rhs) {
        if (lhs instanceof LuaNumber &&
            rhs instanceof LuaNumber) {
                LuaNumber lhsn = (LuaNumber) lhs;
                LuaNumber rhsn = (LuaNumber) rhs;
                return new LuaBool(lhsn.number > rhsn.number);
        }
        
        if (lhs instanceof LuaString &&
            rhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                LuaString rhsn = (LuaString) rhs;
                return new LuaBool(lhsn.luastring.compareTo(rhsn.luastring) > 0);
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

        if (lhs instanceof LuaString &&
            rhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                LuaString rhsn = (LuaString) rhs;
                return new LuaBool(lhsn.luastring.compareTo(rhsn.luastring) >= 0);
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

        if (lhs instanceof LuaString &&
            rhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                LuaString rhsn = (LuaString) rhs;
                return new LuaBool(lhsn.luastring.compareTo(rhsn.luastring) < 0);
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

        if (lhs instanceof LuaString &&
            rhs instanceof LuaString) {
                LuaString lhsn = (LuaString) lhs;
                LuaString rhsn = (LuaString) rhs;
                return new LuaBool(lhsn.luastring.compareTo(rhsn.luastring) <= 0);
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
