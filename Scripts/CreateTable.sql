--Script da lanciare una singola volta per creare le tabelle e inserire una demo dei dati
CREATE TABLE IF NOT EXISTS utente (
                        username VARCHAR(30) NOT NULL,
                        password VARCHAR(30) NOT NULL,
                        admin BOOLEAN NOT NULL DEFAULT false
                        CONSTRAINT utente_pk PRIMARY KEY (username)
);

insert into utente (username, password, admin) values
                       ('ggsolaire', 'password', false),
                       ('Cippolean', 'AOO', default),
                       ('Genny', 'IAmVengeance', true);

CREATE TABLE IF NOT EXISTS luogo (
                        latitudine FLOAT,
                        longitudine FLOAT,
                        nome VARCHAR(50) UNIQUE,  --Poiché non esistono due posti con lo stesso nome
                        categoria VARCHAR(30) DEFAULT '-',
                        CONSTRAINT Luogo_pk PRIMARY KEY (latitudine, longitudine)
);

INSERT INTO luogo (latitudine, longitudine, nome, categoria) VALUES 
                    (12.3375, 45.4341, 'Piazza San Marco', 'Piazza')
                    (12.4924, 41.8902, 'Colosseo', 'Monumento')
                    (11.2549, 43.7764, 'Biblioteca Nazionale Centrale di Firenze', 'Biblioteca')
;


CREATE TABLE IF NOT EXISTS fotografia (
                        id_foto SERIAL PRIMARY KEY,
                        username_proprietario VARCHAR(30) REFERENCES utente(username) ON DELETE CASCADE,  --CASCADE elimina tutte le foto di quell'utente quando l'utente viene eliminato
                        titolo VARCHAR(30) NOT NULL default 'foto.jpg',
                        dati_foto BYTEA,
                        dispositivo VARCHAR(30) NOT NULL DEFAULT 'Sconosciuto',
                        latitudine FLOAT,
                        longitudine FLOAT,
                        condivisa BOOLEAN NOT NULL default false
                        CONSTRAINT fotografia_pk PRIMARY KEY (id_foto),
                        CONSTRAINT fotografia_luogo_fk FOREIGN KEY (latitudine, longitudine) REFERENCES luogo(latitudine,longitudine)
);

CREATE TABLE collezione (
                        id_collezione SERIAL NOT NULL,
                        proprietario VARCHAR(30) NOT NULL,
                        titolo VARCHAR(30) NOT NULL,
                        DataCollezione TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        NumeroElementi INTEGER NOT NULL DEFAULT 0,




);

CREATE TABLE IF NOT EXISTS soggetto (
    id_soggetto SERIAL PRIMARY KEY,
    nome VARCHAR(30),
    categoria VARCHAR(30)   --Se = a 'persona' allora si inserisce anche l'id di tale persona
    id_utente_taggato INTEGER REFERENCES utente(id_utente) DEFAULT NULL
    --Non necessariamente una persona è presente come utente    

);

--Tabella MtM per collegare le fotografie ai soggetti presenti
CREATE TABLE IF NOT EXISTS tags_foto(

);

CREATE TABLE IF NOT EXISTS video (
    id_video SERIAL PRIMARY KEY,
    titolo VARCHAR(30) NOT NULL DEFAULT 'video.mp4',
    username_proprietario VARCHAR(30) REFERENCES utente(username),
    numero_frames INTEGER NOT NULL DEFAULT 0
);
    SLIDE:
    id_foto FK fotografia id
    id_video_appartenenza
    ordine --Slide inserite sequenzialmente
    PER OTTENERE IL NUMERO DELL'ORDINE:
    MAX(ordine) + 1 WHERE id_slideshow = x; dove x è l'id del video modificato

CREATE TABLE IF NOT EXISTS frame(
    id_frame SERIAL PRIMARY KEY,
    id_foto INTEGER REFERENCES fotografia(id_foto),
    id_video_appartenenza INTEGER REFERENCES video(id_video),
    ordine INTEGER DEFAULT 0 --Inserito un Default per avere un valore da cui partire con la funzione di inserimento
                             --Così facendo il primo frame avrà ordine 1
);

--Galleria condivisa di foto tra diversi utenti
CREATE TABLE IF NOT EXISTS shared(
    id_galleria SERIAL PRIMARY KEY,
    id_creatore INTEGER REFERENCES utente(id_utente) ON DELETE CASCADE,
    nome VARCHAR(30)
);
insert into utente values
                       (default, 'ggsolaire', 'password', true),
                       (default, 'Cippolean', 'AOO', default),
                       (default, 'Genny', 'IAmVengeance', false);

INSERT INTO fotografia (username_proprietario, titolo, dati_foto, dispositivo, condivisa, posizione)
VALUES ('ggsolaire', 'Festa in giardino', '0x454F46...', 'iPhone X', false, 'Null Island');

INSERT INTO fotografia (username_proprietario, titolo, dati_foto, condivisa, posizione)
VALUES ('Cippolean', 'Panorama', '0x54875A...', true, 'Piazza San Marco');

INSERT INTO fotografia (username_proprietario, titolo, dati_foto, dispositivo, condivisa)
VALUES ('Genny', 'Il mio cane', '0x897EBA...', 'Samsung Galaxy', true);

INSERT INTO fotografia (username_proprietario, titolo, dati_foto, dispositivo, condivisa)
VALUES ('Cippolean', 'Vacanza estiva', '0xA23C5F...', 'Canon EOS', false);


CREATE PROCEDURE insert_frame_in_video(@id_video INTEGER, @id_foto INTEGER)
    LANGUAGE SQL
    AS $$

        INSERT INTO frame (id_video, id_foto, ordine)
        VALUES (@id_video, @id_foto, (SELECT MAX(ordine) from frame WHERE id_video = @id_video));
    $$;
/*r
--select * from fotografia JOIN luogo ON fotografia.posizione = luogo.nome WHERE luogo.nome = 'Null Island';
--Dopo il nome del campo posso inserire anche un alias ed usare quello al posto del nome
--Esempio fotografia t1 JOIN luogo t2 ON t1.posizione = t2.nome ...
--Scrivere sempre tutti i nomi dei campi negli insert così da evitare problemi qualora si aggiungesse una nuova colonna
*/
/*
    One - to - One
   +-----------+     +----------------+
   | Employees |     | EmployeeDetails |
   +-----------+     +----------------+
   | EmployeeID|-----| EmployeeID      |
   | Name      |     | Address        |
   | Email     |     | Phone          |
   +-----------+     +----------------+
    One - to - Many
   +-----------+     +-------------+
   | Customers |     | Orders      |
   +-----------+     +-------------+
   | CustomerID|-----| CustomerID  |
   | Name      |     | OrderDate   |
   | Email     |     | OrderNumber |
   +-----------+     | TotalPrice  |
                     +-------------+
    Many - to - Many
   +-----------+     +---------+     +------------+
   | Students  |     |Enrollments|   |  Courses   |
   +-----------+     +---------+     +------------+
   | StudentID |----| StudentID|----| CourseID   |
   | Name      |     | CourseID |    | Name      |
   | Email     |     +---------+     |Description|
   +-----------+                     +------------+
 */
