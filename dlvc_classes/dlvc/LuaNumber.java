package dlvc;

class LuaNumber implements LuaType {
    protected Double number;

    public LuaNumber(double n) {
        number = n;
    }

    @Override
    public int hashCode() {
       return number.hashCode(); 
    }
}
