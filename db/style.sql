
DELETE FROM sizing WHERE 1 ;

INSERT INTO sizing (name, sizesid) SELECT 'XXS3XL', id FROM sizes where ranking BETWEEN 10 AND 17 ;
INSERT INTO sizing (name, sizesid) SELECT 'XXS2XL', id FROM sizes where ranking BETWEEN 10 AND 16 ;
INSERT INTO sizing (name, sizesid) SELECT 'XSXL', id FROM sizes where ranking BETWEEN 11 AND 15 ;
INSERT INTO sizing (name, sizesid) SELECT 'XXSXL', id FROM sizes where ranking BETWEEN 10 AND 15 ;
INSERT INTO sizing (name, sizesid) SELECT 'M3XL', id FROM sizes where ranking BETWEEN 13 AND 17 ;
INSERT INTO sizing (name, sizesid) SELECT 'SL', id FROM sizes where ranking IN (12, 14) ;
INSERT INTO sizing (name, sizesid) SELECT 'SML', id FROM sizes where ranking IN (12, 13, 14) ;
INSERT INTO sizing (name, sizesid) SELECT 'LEG', id FROM sizes where code IN ('TW', 'OS', 'TC' ) ;
INSERT INTO sizing (name, sizesid) SELECT 'KLEG', id FROM sizes where code IN ('KS', 'KL' ) ;
INSERT INTO sizing (name, sizesid) SELECT 'KID', id FROM sizes where ranking BETWEEN 40 AND 46 ;
INSERT INTO sizing (name, sizesid) SELECT 'GEN', id FROM sizes where code = 'GEN' ;

DELETE FROM style WHERE 1 ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Amelia', 'dress', 'XXS2XL' ) ;
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
INSERT INTO style (name, `group`, sizing) VALUES ( 'Lindsey', 'kimono', 'SML' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Leggings', 'Leggings', 'LEG' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Kids Leggings', 'kleggings', 'Leggings', 'LEG' ) ;


INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'DotDot Smile', 'ddsmile', 'Kids', 'KID' ) ;
INSERT INTO style (name, folder, `group`, sizing) VALUES ( 'Kids Azure', 'kazure', 'Kids', 'KID' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Sloan', 'Kids', 'KID' ) ;
INSERT INTO style (name, `group`, sizing) VALUES ( 'Gracie', 'Kids', 'KID' ) ;

INSERT INTO style (name, `group`, sizing) VALUES ( 'Combo', '', 'GEN' ) ;

