create table TbCarros(
    id_Carro number primary key not null,
    marca varchar2(40) not null,
    modelo varchar2(40) not null,
    precio number);
    
create table TbInventario(
    placa varchar2(7) primary key not null,
    id_Carro number not null);
    alter table TbInventario add constraint fk_2 FOREIGN KEY(id_Carro) references tbcarros(id_Carro)
    
create table TbCliente(
    id_Cliente number(9) primary key,
    Nombre varchar2(25) not null,
    Apellido varchar2(25) not null,
    correo varchar2(25) not null,
    telefono varchar2(9) not null);
    
--Tabla que guarda reservas activas    
create table TbReserva(
    id_reserva number primary key not null,
    id_cliente number(9)  not null,
    placa varchar2(7) not null,
    metodo_pago varchar2(20) not null,
    precio_rent number not null,
    fecha_inicio date not null,
    fecha_fin date not null),
    foreign key (id_cliente) references tbcliente(id_cliente);
    

--Tabla que almacena temporalmente los carros que están siendo rentados    
create table TbCarrosRentados(
    marca varchar2(40) not null,
    modelo varchar2(40) not null,
    placa varchar2(7) primary key not null);
    
create table auditorias(
    codigo number,
    mensaje varchar(800),
    fecha date,
    origen varchar2(250));
    
--Tabla que guarda todas las reservas a traves del tiempo    
create table registroReservas(
    id_reserva number primary key not null,
    id_cliente number(9)  not null,
    placa varchar2(7) not null,
    metodo_pago varchar2(20) not null,
    precio_rent number not null,
    fecha_inicio date not null,
    fecha_fin date not null);
    
alter table registroReservas add constraint fk_1 FOREIGN KEY (id_cliente) references tbcliente(id_cliente);
-----------------------------------------------------------
CREATE OR REPLACE  PROCEDURE insertar_cliente
    (eid_cliente in number, enombre in varchar2, eapellido in varchar2,
    ecorreo in varchar2, etelefono in varchar2)
    as
        vidcliente number := eid_cliente;
        vnombre varchar2(25) := enombre;
        vapellido varchar2(25) := eapellido;
        vcorreo varchar2(25) := ecorreo;
        vtelefono varchar2(9) := etelefono;
        errcode number;
        errmsg varchar2(100);
    begin
        insert into tbcliente
        (id_cliente, nombre, apellido, correo, telefono)
        values
        (vidcliente, vnombre, vapellido, vcorreo, vtelefono);
        commit;
        exception
            when others then
                errcode := sqlcode;
                errmsg := sqlerrm;
                insert into auditorias values(errcode,errmsg,sysdate,'insertar_cliente');
    end insertar_cliente;

------------------------------------------------------------
create or replace procedure renta_carro(idCar in number)
as
begin
    insert into tbCarrosrentados(placa,marca,modelo)
        select i.placa, c.marca, c.modelo
        from tbcarros c, tbinventario i where (i.id_carro = c.id_carro and c.id_carro = idCar) and rownum =1;
        commit;
end;

create or replace trigger eliminar_carro_tbcarro
after insert on tbCarrosrentados
for each row
begin
    delete from tbinventario where placa = :new.placa;
end;

---------------------------------------------------------
    create or replace procedure reservar_carro
    (eid_reserva in number, eid_cliente in number, eMonto in number,vplaca in varchar2,
    emetodo_pago in varchar2, efecha_inicio in varchar2, efecha_fin in varchar2)
    as
        vidReserva number := eid_reserva;
        vidCliente number := eid_cliente;
        vmetodo varchar2(20) := emetodo_pago;
        inicio_rent date := TO_DATE(efecha_inicio,'YYYY-MM-DD');
        fin_rent date := TO_DATE(efecha_fin,'YYYY-MM-DD');
        monto number;
        vidcarro number;
        errmsg varchar2(100);
        errcode number;
    begin
        select c.id_carro
        into vidcarro
        from tbcarros c, tbinventario i
        where c.id_carro = i.id_carro
        and i.placa = vplaca;
        

        monto := eMonto;
    
        insert into tbreserva
        (id_reserva,id_cliente,placa,metodo_pago,precio_rent,fecha_inicio,fecha_fin) 
        values
        (vidReserva,vidCliente,vplaca,vmetodo,monto,inicio_rent,fin_rent);
        renta_carro(vidcarro);
        exception
            when no_data_found then
                errcode := sqlcode;
                errmsg := sqlerrm;
                insert into auditorias values (errcode, errmsg, sysdate, 'inserciones.reservar_carro');
            when too_many_rows then
                errcode := sqlcode;
                errmsg := sqlerrm;
                insert into auditorias values (errcode, errmsg, sysdate, 'inserciones.reservar_carro');
            when others then
                errcode := sqlcode;
                errmsg := sqlerrm;
                insert into auditorias values (errcode, errmsg, sysdate, 'inserciones.reservar_carro');
        
    end;
--------------------


------------------
   


create or replace package consultas as
    function checkinventario(id_carro in number) return number;
    function checkCliente(cedula in number) return varchar2;
    procedure obtenerCliente(cedula in number, resultado out SYS_REFCURSOR);
end;

create or replace package body consultas as
    function checkinventario(id_carro in number) return number is
        vsql varchar2(120);
        cantidad number;
    begin
            vsql := 'select count(*) from tbinventario where id_carro =: idC ';
            EXECUTE IMMEDIATE vsql into cantidad using id_carro;
            return cantidad;
    end checkinventario;
    ---------------------------------------------------------------
    function checkCliente(cedula in number) return varchar2 is
        contador number;
        vsql varchar2(60);
    begin
        vsql:='SELECT count(*) from tbCliente where id_Cliente =: idC';
        EXECUTE IMMEDIATE vsql into contador using cedula;
        IF contador>0 THEN
            RETURN 'true';
        ELSE
            RETURN 'false';
      END IF;
    end checkCliente;
    -------------------------------------
    procedure obtenerCliente(cedula in number, resultado out SYS_REFCURSOR) as
    begin
        open resultado for
        SELECT * FROM tbCliente
        WHERE id_cliente = cedula;
    end obtenerCliente;
end consultas;
    



-------------------------------------------------

create or replace procedure liberar_carro(plc in varchar2)
as
    idcarro varchar2(20) := plc;
begin
    insert into tbinventario(placa,id_carro)
        select t.placa,c.id_carro
        from tbcarros c inner join tbcarrosrentados t
        on t.modelo = c.modelo
        where t.placa = plc;
    delete from tbcarrosrentados where placa = idcarro;
    delete from tbreserva where placa = idcarro;
    commit;
end;

 
create or replace procedure obtenerInventario(resultado out sys_refcursor) as
begin
    open resultado for
     select i.placa, c.marca, c.modelo
    from tbcarros c, tbinventario i
    where i.id_carro = c.id_carro;
end;



create or replace procedure obtener_carro(cId in number, resul out sys_refcursor) as
begin
open resul for 
select c.id_carro, c.marca,c.modelo,c.precio,i.placa
from tbcarros c, tbinventario i
where (c.id_carro = i.id_carro and c.id_carro=cId) and rownum= 1;
end;


create or replace procedure obtenerReservas(resul out sys_refcursor) as
begin
    open resul for
  select r.id_reserva as "idReserva" ,r.placa as "Placa",r.id_cliente as"idCliente",(cliente.nombre||' '||cliente.apellido) as "Nombre" ,i.marca,i.modelo,to_char(r.fecha_inicio,'DD-MM-YYYY') as "fechaInicio",to_char(r.fecha_fin,'DD-MM-YYY') as "fechaFin" 
    from 
    tbreserva r, tbcliente cliente, tbcarrosrentados i 
    where r.id_cliente = cliente.id_cliente and i.placa = r.placa;
end;

  
create or replace trigger pasar_a_registro 
before delete on tbreserva 
for each row
BEGIN
    insert into registroReservas values (:old.id_reserva,:old.id_cliente,:old.placa,:old.metodo_pago,:old.precio_rent,:old.fecha_inicio,:old.fecha_fin);
END;
 


