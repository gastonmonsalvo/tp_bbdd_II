CREATE DATABASE TiendaMusicaSimple;
USE TiendaMusicaSimple;

    -- Hipotesis: Se tiene una tienda de musica , la cual realiza ventas a sus clientes
        -- Se cuenta con las entidades Categorias, Productos, Clientes, Ventas y Detalle


CREATE TABLE Clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    dni VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100),
    telefono DOUBLE UNSIGNED NOT NULL
);

CREATE TABLE Categorias (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL 
);


CREATE TABLE Productos (
    id_producto INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    marca VARCHAR(50),
    precio DECIMAL(10, 2) NOT NULL ,
    stock INT NOT NULL,
    id_categoria INT,
    FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria)
);

CREATE TABLE Ventas (
    id_venta INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    id_cliente INT,
    metodo_pago ENUM('Efectivo', 'Tarjeta', 'Transferencia') NOT NULL,
    total DECIMAL(12, 2) DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

CREATE TABLE Detalle_Ventas (
    id_detalle INT PRIMARY KEY AUTO_INCREMENT,
    id_venta INT,
    id_producto INT,
    cantidad INT NOT NULL ,
    subtotal DECIMAL(10, 2),
    FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);

-- Carga de Datos

INSERT INTO Categorias (nombre) 
VALUES ('Guitarras'), ('Teclados'), ('Accesorios');


INSERT INTO Productos (nombre, marca, precio, stock, id_categoria)
VALUES  ('Stratocaster', 'Fender', 150000.00, 5, 1),
        ('Sintetizador Minilogue', 'Korg', 95000.00, 3, 2),
        ('Cuerdas 0.10', 'Ernie Ball', 1200.00, 50, 3),
        ('Gibson', 'Les Paul', 180000.00, 3, 1);


INSERT INTO Clientes (nombre, dni, email,telefono) 
VALUES 
        ('Charly Garcia', '10123456', 'charly@saynomore.com', 1155555555),
        ('Luis Spinetta', '11222333', 'luis@flaco.com', 1177777777),
        ('Alejandro Magno', '22444312', 'macedonia@rules.com', 1188888888);


INSERT INTO Ventas (id_cliente, metodo_pago, total) VALUES (1, 'Tarjeta', 150200.00);


INSERT INTO Detalle_Ventas (id_venta, id_producto, cantidad, subtotal) 
VALUES 
        (1, 1, 1, 15000.00),
        (1, 3, 1, 1200.00);


-- objetos

-- PROCEDURE para simplificar el registro de venta y descuento segun metodo de pago elegido
    -- h1: las ventas en efectivo tienen 15% de descuento, las ventas por transferencia bancaria el 5%

DELIMITER $$
DROP PROCEDURE IF EXISTS registrar_venta_simplificada$$

CREATE PROCEDURE registrar_venta_simplificada(
    IN p_id_cliente INT,
    IN p_metodo_pago VARCHAR(20),
    IN p_monto_base DECIMAL(10,2),
    OUT p_monto_final DECIMAL(10,2)
)

BEGIN
    DECLARE v_descuento DECIMAL(5,2);

    CASE p_metodo_pago
        WHEN 'Efectivo' THEN SET v_descuento = 0.15; 
        WHEN 'Transferencia' THEN SET v_descuento = 0.05; 
        ELSE SET v_descuento = 0.00; 
    END CASE;

    SET p_monto_final  = p_monto_base * (1 - v_descuento);

    INSERT INTO Ventas (id_cliente, metodo_pago, total) 
    VALUES (p_id_cliente, p_metodo_pago,p_monto_final );

END $$

DELIMITER ;

-- prueba
CALL registrar_venta_con_retorno(1, 'Efectivo', 1000.00, @total_calculado);
SELECT @total_calculado;
-- Res esperado = 850


-- TRIGGER mantener el stock al dia  
    -- h2: necesidad de actualizar el stock por ventas

DELIMITER $$

CREATE TRIGGER tg_actualizar_stock
AFTER INSERT ON Detalle_Ventas
FOR EACH ROW
BEGIN

    IF  (SELECT stock 
        FROM Productos 
        WHERE id_producto = NEW.id_producto) >= NEW.cantidad THEN
        UPDATE Productos 
        SET stock = stock - NEW.cantidad 
        WHERE id_producto = NEW.id_producto;
    END IF;
END $$

DELIMITER ;


-- FUNCTION para calcular el IVA
    -- h2: se debe calcular al precio del producto luego del descuento el IVA 21%

DELIMITER $$

CREATE FUNCTION fn_calcular_iva(p_precio DECIMAL(10,2)) 

RETURNS DECIMAL(10,2)
DETERMINISTIC

BEGIN
    DECLARE valor_con_iva DECIMAL(10,2);
    
    SET valor_con_iva = p_precio * 0.21;
    
    RETURN valor_con_iva;
END $$

DELIMITER ;