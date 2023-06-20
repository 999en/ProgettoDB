--Script da lanciare una singola volta per creare le tabelle e inserire una demo dei dati
CREATE TABLE IF NOT EXISTS utente (
                        username VARCHAR(30) NOT NULL,
                        password VARCHAR(30) NOT NULL,
                        admin BOOLEAN NOT NULL DEFAULT false,
                        CONSTRAINT utente_pk PRIMARY KEY (username)
);

CREATE TABLE IF NOT EXISTS luogo (
                        latitudine FLOAT NOT NULL,
                        longitudine FLOAT NOT NULL,
                        nome VARCHAR(50) UNIQUE,  --Poiché non esistono due posti con lo stesso nome
                        descrizione VARCHAR(225),
                        CONSTRAINT luogo_pk PRIMARY KEY (latitudine, longitudine)
);

CREATE TABLE IF NOT EXISTS fotografia (
                        id_foto SERIAL NOT NULL, --SERIAL indica un BIG INT con sequenza auto gestita dal DB
                        username_autore VARCHAR(30),
                        dati_foto BYTEA,
                        dispositivo VARCHAR(30) NOT NULL DEFAULT 'Sconosciuto',
                        data_foto TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        latitudine FLOAT,
                        longitudine FLOAT,
                        condivisa BOOLEAN NOT NULL default false,
                        CONSTRAINT fotografia_pk PRIMARY KEY (id_foto),
                        CONSTRAINT fotografia_autore_fk FOREIGN KEY (username_autore) REFERENCES utente(username) ON DELETE CASCADE, --CASCADE elimina tutte le foto di quell'utente quando l'utente viene eliminato
                        titolo VARCHAR(30) NOT NULL default 'foto.jpg',
                        CONSTRAINT fotografia_luogo_fk FOREIGN KEY (latitudine, longitudine) REFERENCES luogo(latitudine,longitudine)
);

CREATE TABLE IF NOT EXISTS collezione (         
                        id_collezione INTEGER NOT NULL,
                        username VARCHAR(30) NOT NULL,
                        titolo VARCHAR(30) NOT NULL,
                        data_collezione TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        numero_elementi INTEGER NOT NULL DEFAULT 0,
                        CONSTRAINT collezione_pk PRIMARY KEY (id_collezione),
                        CONSTRAINT collezione_utente_fk FOREIGN KEY (username) REFERENCES utente(username) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS contenuto(
                        id_collezione INTEGER NOT NULL,
                        id_foto INTEGER NOT NULL,
                        CONSTRAINT contenuto_pk PRIMARY KEY (id_collezione, id_foto),
                        CONSTRAINT contenuto_collezione_fk FOREIGN KEY (id_collezione) REFERENCES collezione(id_collezione) ON DELETE CASCADE,
                        CONSTRAINT contenuto_fotografia_fk FOREIGN KEY (id_foto) REFERENCES fotografia(id_foto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tag_utente(
                        username VARCHAR(30) NOT NULL,
                        id_foto INTEGER NOT NULL,
                        CONSTRAINT tag_utente_pk PRIMARY KEY (username, id_foto),
                        CONSTRAINT tagutente_utente_fk FOREIGN KEY(username) REFERENCES utente(username) ON DELETE CASCADE,
                        CONSTRAINT tagutente_fotografia_fk FOREIGN KEY(id_foto) REFERENCES fotografia(id_foto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS video (
    id_video SERIAL NOT NULL,
    autore VARCHAR(30) NOT NULL,
    titolo VARCHAR(30) NOT NULL DEFAULT 'video.mp4',
    numero_frames INTEGER NOT NULL DEFAULT 0,
    durata INTEGER NOT NULL DEFAULT 0,
    descrizione VARCHAR(225),
    CONSTRAINT video_pk PRIMARY KEY (id_video),
    CONSTRAINT video_autore_fk FOREIGN KEY (autore) REFERENCES utente(username) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS frame(
    id_video INTEGER NOT NULL,
    id_foto INTEGER,
    durata INTEGER NOT NULL DEFAULT 0,
    ordine INTEGER NOT NULL DEFAULT 0, --Inserito un Default per avere un valore da cui partire con la funzione di inserimento
                                             --Così facendo il primo frame avrà ordine 1
    CONSTRAINT frame_pk PRIMARY KEY (id_video, ordine),
    CONSTRAINT frame_video_fk FOREIGN KEY (id_video) REFERENCES video(id_video) ON DELETE CASCADE,
    CONSTRAINT frame_fotografia_fk FOREIGN KEY (id_foto) REFERENCES fotografia(id_foto) ON DELETE SET NULL
                                                                                    --"ON DELETE SET NULL" indica che quando una riga
                                                                                    --nella tabella padre viene eliminata, il valore della colonna                                                                              --corrispondente nella tabella figlia deve essere impostato a NULL.
);

CREATE TABLE IF NOT EXISTS soggetto (
    nome VARCHAR(30) NOT NULL,
    categoria VARCHAR(30) NOT NULL DEFAULT '-',
    CONSTRAINT soggetto_pk PRIMARY KEY (nome)
);

CREATE TABLE IF NOT EXISTS tag_soggetto(
    nome_soggetto VARCHAR(30) NOT NULL,
    id_foto INTEGER NOT NULL,
    CONSTRAINT tag_soggetto_pk PRIMARY KEY (nome_soggetto, id_foto),
    CONSTRAINT tagsottetto_soggetto_fk FOREIGN KEY (nome_soggetto) REFERENCES soggetto(nome),
    CONSTRAINT tagsoggetto_fotografia_fk FOREIGN KEY (id_foto) REFERENCES fotografia(id_foto)
);
