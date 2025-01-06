

insert into categories (category_id, name, necessity) values
(1, 'Processor', true),
(2, 'Motherboard', true),
(3, 'RAM', true),
(4, 'Storage', true),
(5, 'GPU', false),
(6, 'Power Supply', true),
(7, 'Cooling System', false),
(8, 'Case', true),
(9, 'Monitor', false),
(10, 'Keyboard', false),
(11, 'Mouse', false),
(12, 'Sound Card', false),
(13, 'Network Card', false),
(14, 'Optical Drive', false),
(15, 'Speakers', false),
(16, 'Webcam', false),
(17, 'Headphones', false),
(18, 'Printer', false),
(19, 'Scanner', false),
(20, 'UPS', false);


insert into components (component_id, name, category_id, price, guarantee_period) values
(1, 'Intel Core i9', 1, 500, 36),
(2, 'AMD Ryzen 7', 1, 450, 36),
(3, 'ASUS Prime', 2, 150, 24),
(4, 'MSI Pro', 2, 140, 24),
(5, 'Corsair Vengeance 16GB', 3, 80, 24),
(6, 'Kingston HyperX 16GB', 3, 75, 24),
(7, 'Samsung 1TB SSD', 4, 100, 60),
(8, 'Seagate 2TB HDD', 4, 60, 36),
(9, 'NVIDIA RTX 3080', 5, 700, 36),
(10, 'AMD Radeon RX 6700 XT', 5, 650, 36),
(11, 'Cooler Master PSU 600W', 6, 120, 36),
(12, 'Thermaltake PSU 650W', 6, 110, 36),
(13, 'Noctua CPU Cooler', 7, 75, 36),
(14, 'Cooler Master Case', 8, 90, 36),
(15, 'Dell Monitor 24"', 9, 200, 36),
(16, 'Logitech Keyboard', 10, 50, 24),
(17, 'Razer Mouse', 11, 60, 24),
(18, 'Creative Sound Blaster', 12, 50, 24),
(19, 'TP-Link Network Card', 13, 30, 24),
(20, 'Canon Printer', 18, 120, 12);



insert into computers (serial_number, provider_id) values
(1001, 1),
(1002, 2),
(1003, 3),
(1004, 1),
(1005, 2),
(1006, 1),
(1007, 3),
(1008, 2),
(1009, 1),
(1010, 3),
(1011, 2),
(1012, 3),
(1013, 1),
(1014, 2),
(1015, 3),
(1016, 1),
(1017, 3),
(1018, 2),
(1019, 1),
(1020, 3);


insert into computer_components (computer_serial_number, component_id, sale_date, computer_sale_price) values
(1001, 1, '2023-11-01', 1200),
(1001, 3, '2023-11-01', 1200),
(1001, 5, '2023-11-01', 1200),
(1002, 1, '2023-10-15', 1100),
(1002, 3, '2023-10-15', 1100),
(1002, 8, '2023-10-15', 1100),
(1003, 2, '2023-09-10', 1400),
(1003, 4, '2023-09-10', 1400),
(1003, 7, '2023-09-10', 1400),
(1004, 1, '2023-11-20', 1350),
(1004, 5, '2023-11-20', 1350),
(1004, 6, '2023-11-20', 1350),
(1005, 2, '2023-08-05', 1150),
(1005, 3, '2023-08-05', 1150),
(1005, 4, '2023-08-05', 1150),
(1006, 1, '2023-07-18', 1300),
(1006, 8, '2023-07-18', 1300),
(1006, 11, '2023-07-18', 1300),
(1007, 2, '2023-06-20', 10),
(1007, 1, '2023-06-20', 10);


