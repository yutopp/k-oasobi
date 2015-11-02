x := 3;
y := 0;

begin proc fac is begin var z := x;
                        if x = 1 then skip
                        else (x := x-1; call fac; y := z*y)
                  end;
      (y := 1; call fac)
end
