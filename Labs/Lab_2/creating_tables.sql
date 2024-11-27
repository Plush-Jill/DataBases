
CREATE TABLE categories(
    category_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    necessity BOOLEAN DEFAULT FALSE
);

CREATE TABLE components(
    component_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    category_id INT NOT NULL references categories(category_id),
    price INT NOT NULL,
    guarantee_period INT NOT NULL
);

CREATE TABLE computers(
    serial_number INT PRIMARY KEY,
    provider_id INT NOT NULL
);

CREATE TABLE computer_components (
    computer_serial_number INT REFERENCES computers(serial_number),
    component_id INT REFERENCES components(component_id),
    sale_date DATE,
    computer_sale_price INT,
    PRIMARY KEY(computer_serial_number, component_id)
);
