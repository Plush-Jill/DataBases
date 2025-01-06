

create table categories(
    category_id int primary key ,
    name varchar(50) not null ,
    necessity boolean
);
create table components(
    component_id int primary key,
    name varchar(50) not null unique,
    category_id int not null references categories(category_id),
    price int not null ,
    guarantee_period int not null
);

create table computers(
    serial_number int primary key,
    provider_id int not null
);

create table computer_components (
    computer_serial_number int references computers(serial_number),
    component_id int references components(component_id),
    sale_date DATE,
    computer_sale_price int,
    primary key (computer_serial_number, component_id)
);
