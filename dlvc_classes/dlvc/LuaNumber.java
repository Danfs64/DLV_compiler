package dlvc;

public class LuaNumber implements LuaType {
    protected Double number;

    public LuaNumber(double n) {
        number = n;
    }

    @Override
    public int hashCode() {
       return number.hashCode(); 
    }

    @Override
    public boolean equals(Object o) {
        if (o instanceof LuaNumber) {
            LuaNumber ol = (LuaNumber) o;
            return Double.compare(this.number, ol.number) == 0;
        }
        return false;
    }

    public void print() {
        System.out.println(number);
    }

    @Override
    public String toString() {
        if (number > Math.floor(number)) {
            return String.valueOf(number);
        } else {
            return String.valueOf(number.longValue());
        }
    }

    public boolean boolValue() {
        return true;
    }

    public LuaType negate() {
        return new LuaNumber(-number);
    }
}
