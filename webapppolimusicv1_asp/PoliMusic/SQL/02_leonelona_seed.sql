-- =====================================================================
--  PoliMusic - Usuario estandar de referencia (LeonelOna)
-- ---------------------------------------------------------------------
--  El script 01_BDD_PoliMusic.sql crea los usuarios userNormal,
--  userAdmin y username1, pero NO crea a LeonelOna, que es la cuenta
--  de perfil estandar usada por la aplicacion. Este script la anade
--  de forma idempotente (se puede ejecutar varias veces sin error).
--
--  Credenciales resultantes:  LeonelOna / 123456789
--  La contrasena se guarda como SHA-1 hexadecimal, igual que el resto
--  de cuentas gestionadas por la aplicacion.
--
--  Uso:
--    sqlcmd -S localhost,1433 -U usr_polimusic -P Politecnica1 -C ^
--           -d BDD_PoliMusic -i 02_leonelona_seed.sql
-- =====================================================================

USE [BDD_PoliMusic];
GO

IF NOT EXISTS (SELECT 1 FROM dbo.TBL_USER WHERE USERNAME = 'LeonelOna')
BEGIN
    INSERT INTO dbo.TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE)
    VALUES (
        'LeonelOna',
        CONVERT(varchar(40), HASHBYTES('SHA1', '123456789'), 2),
        'leonel.onacevallos@epn.edu.ec',
        '2000-12-15',
        '~/userImages/default.jpg',
        0            -- 0 = usuario estandar, 1 = administrador
    );
    PRINT 'Usuario LeonelOna creado (perfil estandar).';
END
ELSE
BEGIN
    PRINT 'El usuario LeonelOna ya existe.';
END
GO

SELECT ID_USER, USERNAME, EMAIL, USER_TYPE
FROM dbo.TBL_USER
ORDER BY ID_USER;
GO
