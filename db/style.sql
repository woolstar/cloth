
DELETE FROM sizing WHERE 1 ;

INSERT INTO sizing (name, sizes_id) SELECT 'XXS3XL', sizes_id FROM sizes where ranking BETWEEN 10 AND 17 ;
INSERT INTO sizing (name, sizes_id) SELECT 'XS3XL', sizes_id FROM sizes where ranking BETWEEN 11 AND 17 ;
INSERT INTO sizing (name, sizes_id) SELECT 'XXS2XL', sizes_id FROM sizes where ranking BETWEEN 10 AND 16 ;
INSERT INTO sizing (name, sizes_id) SELECT 'XSXL', sizes_id FROM sizes where ranking BETWEEN 11 AND 15 ;
INSERT INTO sizing (name, sizes_id) SELECT 'XXSXL', sizes_id FROM sizes where ranking BETWEEN 10 AND 15 ;
INSERT INTO sizing (name, sizes_id) SELECT 'M3XL', sizes_id FROM sizes where ranking BETWEEN 13 AND 17 ;
INSERT INTO sizing (name, sizes_id) SELECT 'SL', sizes_id FROM sizes where ranking IN (12, 14) ;
INSERT INTO sizing (name, sizes_id) SELECT 'SML', sizes_id FROM sizes where ranking IN (12, 13, 14) ;
INSERT INTO sizing (name, sizes_id) SELECT 'LEG', sizes_id FROM sizes where code IN ('TW', 'OS', 'TC' ) ;
INSERT INTO sizing (name, sizes_id) SELECT 'KLEG', sizes_id FROM sizes where code IN ('KS', 'KL' ) ;
INSERT INTO sizing (name, sizes_id) SELECT 'KID', sizes_id FROM sizes where code IN ( 'K2', 'K4', 'K6', 'K8', 'K10', 'K12', 'K14') ;
INSERT INTO sizing (name, sizes_id) SELECT 'KDRESS', sizes_id FROM sizes where ranking BETWEEN 50 AND 55 ;
INSERT INTO sizing (name, sizes_id) SELECT 'K123', sizes_id FROM sizes where ranking BETWEEN 40 AND 42 ;
INSERT INTO sizing (name, sizes_id) SELECT 'GEN', sizes_id FROM sizes where code = 'GEN' ;

DELETE FROM style WHERE 1 ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Amelia', 'dress', 'XXS3XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Ana', 'dress', 'XS3XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Julia', 'dress', 'XXS3XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Nicole', 'dress', 'XXS3XL' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Azure', 'skirt', 'XXS2XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Cassie', 'skirt', 'XXS3XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Lucy', 'skirt', 'XXS2XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Maxi', 'skirt', 'XXS3XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Madison', 'skirt', 'XSXL' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Irma', 'top', 'XXSXL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Randy', 'top', 'XXS3XL' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Classic T', 'classict', 'top', 'XXS3XL' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Perfect T', 'perfectt', 'top', 'XXS3XL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Patrick', 'top', 'M3XL' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Monroe', 'kimono', 'SL' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Lindsay', 'kimono', 'SML' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Leggings', 'Leggings', 'LEG' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Kids Leggings', 'kleggings', 'Leggings', 'KLEG' ) ;


INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'DotDot Smile Lucy', 'ddsmile', 'Kids', 'KDRESS' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Kids Azure', 'kazure', 'Kids', 'KID' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Sloan', 'Kids', 'KID' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Gracie', 'Kids', 'KID' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Adeline', 'adeline', 'Kids', 'KID' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Mae', 'mae', 'Kids', 'KID' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Combo', '', 'GEN' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Carly', 'dress', 'XXS3XL' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Sarah', 'sarah', 'sweater', 'XSXL' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Mark', 'mark', 'Men', 'M3XL' ) ;

INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Bianka', 'bianka', 'kimono', 'KID' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Scarlett', 'scarlett', 'Kids', 'KID' ) ;

