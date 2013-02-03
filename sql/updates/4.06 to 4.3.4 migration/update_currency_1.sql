
DROP PROCEDURE IF EXISTS `temp_update_currency_1`;
delimiter //
CREATE PROCEDURE `temp_update_currency_1`()
    LANGUAGE SQL
    NOT DETERMINISTIC
    CONTAINS SQL
    SQL SECURITY DEFINER
    COMMENT 'Reset justice and valor points.'
BEGIN
DECLARE guid INT DEFAULT 0;
DECLARE currency INT DEFAULT 0;
DECLARE justice INT DEFAULT 0;
DECLARE valor INT DEFAULT 0;
DECLARE counts INT DEFAULT 0;
DECLARE done INT DEFAULT 0;
DECLARE money INT DEFAULT 0;
DECLARE cur CURSOR FOR SELECT `character_currency`.`guid`, `character_currency`.`currency`, `character_currency`.`total_count` FROM `character_currency` WHERE `character_currency`.`currency` IN (395, 396) AND `character_currency`.`guid`=15 ORDER BY `character_currency`.`guid`, `character_currency`.`currency`;
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1; 
-- sort rows
-- there are 2 rows per guid (currencies 395 and 396)
-- it may be only one currency but 396 is always last by sorting
-- so if we have 396 currency in rows - it is last currency for that character and we can calculate
OPEN cur; 
WHILE done = 0 DO
    FETCH cur INTO guid, currency, counts;

    -- save current justice points
    IF currency = 395 THEN
        SET justice = counts;
    END IF;
    
    -- add valor points to justice points
    -- if justice points are over 4000(00) we will correct it and save diff
    -- we will add diff to player's money
    -- the rate is 47 silver per point
    IF currency = 396 THEN
        SET valor = counts;
        IF justice < 400000 THEN
            SET justice = justice + valor;
            IF justice > 400000 THEN
                -- calculate money immediately
                SET money = (justice - 400000) * 47;
                SET justice = 400000;
            END IF;
        END IF;
        UPDATE `character_currency` SET `character_currency`.`total_count`=justice WHERE `character_currency`.`guid`=guid AND `character_currency`.`currency`=395;
        -- if we have money, we have to add them to the player
        IF money > 0 THEN
            UPDATE `characters` SET `characters`.`money`=`characters`.`money` + money WHERE `characters`.`guid`=guid;
        END IF;
        -- clear all variables
        SET justice = 0;
        SET currency = 0;
        SET valor = 0;
        SET money = 0;
    END IF;
END WHILE;
CLOSE cur;

END;
//
delimiter ;

CALL `temp_update_currency_1`;

DROP PROCEDURE IF EXISTS `temp_update_currency_1`;

-- Clear all valor points
UPDATE `character_currency` SET `character_currency`.`total_count`=0 WHERE `character_currency`.`currency`=396;
