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


---------------------------------------------------------------------------------------------------------------------------------------------
--Trigger che aggiorna gli elementi di una galleria
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION aggiorna_elementi_galleria() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE collezione SET numero_elementi = numero_elementi + 1 WHERE id_collezione = NEW.id_collezione;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE collezione SET numero_elementi = numero_elementi - 1 WHERE id_collezione = OLD.id_collezione;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER aggiorna_elementi_galleria_trigger
AFTER INSERT OR DELETE ON contenuto
FOR EACH ROW
EXECUTE FUNCTION aggiorna_elementi_galleria();


---------------------------------------------------------------------------------------------------------------------------------------------
-- Trigger per aggiornare automaticamente il valore dell'attributo "numero_frames"
-- quando si inserisce o si elimina un frame nella tabella "frame":
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_video_frame_count() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE video SET numero_frames = numero_frames + 1 WHERE id_video = NEW.id_video;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE video SET numero_frames = numero_frames - 1 WHERE id_video = OLD.id_video;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_video_frame_count_trigger
AFTER INSERT OR DELETE ON frame
FOR EACH ROW
EXECUTE FUNCTION update_video_frame_count();


---------------------------------------------------------------------------------------------------------------------------------------------
-- Trigger per generare automaticamente il valore dell'attributo "ordine"
-- quando si inserisce un nuovo frame nella tabella "frame":
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_frame_order() RETURNS TRIGGER AS $$
BEGIN
    NEW.ordine := (SELECT COALESCE(MAX(ordine), 0) FROM frame WHERE id_video = NEW.id_video) + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER frame_order_trigger
BEFORE INSERT ON frame
FOR EACH ROW
EXECUTE FUNCTION generate_frame_order();

---------------------------------------------------------------------------------------------------------------------------------------------
-- Trigger per aggiorare automaticamente il valore dell' attributo "durata" nella tabella "video"
-- quando si inserisce un nuovo frame nella tabella "frame" oppure si modifica la durata di un frame:
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_video_duration() RETURNS TRIGGER AS $$
BEGIN
  UPDATE video
  SET durata = (
    SELECT SUM(durata)
    FROM frame
    WHERE id_video = NEW.id_video
  )
  WHERE id_video = NEW.id_video;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_video_duration
AFTER INSERT OR UPDATE ON frame
FOR EACH ROW
EXECUTE FUNCTION update_video_duration();



---------------------------------------------------------------------------------------------------------------------------------------------
--Classifica dei top 3 luoghi più immortalati.
---------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW ClassificaLuoghi AS
SELECT latitudine, longitudine, nome, descrizione, COUNT(id_foto) AS NumeroFotografie
FROM luogo NATURAL LEFT JOIN fotografia
GROUP BY latitudine, longitudine, nome, descrizione
ORDER BY NumeroFotografie DESC, nome ASC
LIMIT 3;

--View per mostrare gli utenti dell'applicativo
CREATE OR REPLACE VIEW ShowUser AS
SELECT DISTINCT username
FROM utente;

--View per mostrare gli admin dell'applicativo
CREATE OR REPLACE VIEW ShowAdmin AS
SELECT DISTINCT username, admin
FROM utente
WHERE admin = true;

--View per visualizzare i dati di ogni frame che è utilizzato in almeno un video
CREATE OR REPLACE VIEW ContenutoFrame AS
SELECT fotografia.dati_foto, frame.*
FROM fotografia
INNER JOIN frame ON fotografia.id_foto = frame.id_foto;

--View per visualizzare una lista delle categorie dei soggetti nel database
CREATE OR REPLACE VIEW CategoriaSoggetto AS
SELECT DISTINCT soggetto.categoria
FROM soggetto;

--View per lista di tutti i video
CREATE OR REPLACE VIEW ShowVideos AS
SELECT titolo AS "Titolo", autore AS "Autore", descrizione AS "Info"
FROM video;



---------------------------------------------------------------------------------------------------------------------------------------------
--Funzioni per mostrare la galleria personale di un utente
-- "Ogni utente ha sempre la possibilità di vedere la propria personale galleria fotografica, che comprende esclusivamente le foto scattate da lui."
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GalleriaUtente (Utente utente.username%TYPE, Richiedente utente.username%TYPE) RETURNS SETOF fotografia AS
$$
BEGIN
    RETURN QUERY (
        SELECT * FROM fotografia
        WHERE fotografia.username_autore = Utente AND (
            fotografia.username_autore = Richiedente OR fotografia.condivisa = TRUE
        )
    );
END;
$$ LANGUAGE plpgsql;


--Collezioni di un utente
CREATE OR REPLACE FUNCTION CollezioniUtente(utente utente.username%TYPE) RETURNS SETOF collezione AS
$$
BEGIN
    RETURN QUERY (
        SELECT * FROM collezione
        WHERE collezione.username = utente
    );
END;
$$LANGUAGE plpgsql;

--Contenuto di una Collezione condivisa
CREATE OR REPLACE FUNCTION ContenutoCollezione (collezione collezione.id_collezione%TYPE) RETURNS SETOF fotografia AS
$$
BEGIN
    RETURN QUERY(
        SELECT fotografia.*
        FROM contenuto NATURAL JOIN fotografia
        WHERE id_collezione = collezione
    );
END;
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------------------------------------
--Recupero di tutte le fotografie che sono state scattate nello stesso luogo SECONDO
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION foto_per_luogo(in_nome luogo.nome%TYPE, utente fotografia.username_autore%TYPE)
RETURNS SETOF fotografia AS
$$
BEGIN
    RETURN QUERY (
        SELECT fotografia.*
        FROM fotografia
        JOIN luogo ON fotografia.latitudine = luogo.latitudine AND fotografia.longitudine = luogo.longitudine
        WHERE luogo.nome = in_nome AND (
            fotografia.username_autore = utente OR fotografia.condivisa = TRUE
        )
    );
END;
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------------------------------------
--Recupero di tutte le fotografie che condividono lo stesso utente come soggetto
---------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION foto_per_tag_utente(in_username tag_utente.username%TYPE)
RETURNS SETOF fotografia AS
$$
BEGIN
    RETURN QUERY (
        SELECT fotografia.*
        FROM fotografia
        JOIN tag_utente ON tag_utente.id_foto = fotografia.id_foto
        WHERE tag_utente.username = in_username
    );
END;
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------------------------------------
--Recupero di tutte le fotografie che condividono lo stesso soggetto;
---------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION foto_per_tag_soggetto(in_nome_soggetto tag_soggetto.nome_soggetto%TYPE, utente_richiedente fotografia.username_autore%TYPE)
RETURNS SETOF fotografia AS
$$
BEGIN
    RETURN QUERY (
        SELECT fotografia.*
        FROM fotografia
        JOIN tag_soggetto ON tag_soggetto.id_foto = fotografia.id_foto
        WHERE tag_soggetto.nome_soggetto = in_nome_soggetto AND (
			fotografia.username_autore= utente_richiedente OR fotografia.condivisa = TRUE)
    );
END;
$$ LANGUAGE plpgsql;


--view per visualizzare un video come un insieme di frame
CREATE OR REPLACE FUNCTION visualizza_video(in_titolo video.titolo%TYPE)
RETURNS SETOF frame AS
$$
BEGIN
    RETURN QUERY (
        SELECT frame.*
        FROM frame
        JOIN video ON video.id_video = frame.id_video
        WHERE video.titolo = in_titolo
		ORDER BY ordine
    );
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------------------------------------------------------
--“L’amministratore del sistema può eliminare un utente: in tal caso, tutte le foto dell’utente verranno cancellate dalla libreria, eccetto
--quelle che contengono come soggetto un altro degli utenti della galleria condivisa."

--Per eseguire questo vincolo setteremo a NULL tutte le foto che ha scattato l'utente dove ha un tag_utente in questo modo quando andremo ad eliminare
--L'utente verranno eliminate solo le foto non condivise grazie al "Delete on Cascade" nella tabella fotografia
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION save_tagphoto()
RETURNS TRIGGER AS
$$
BEGIN
	UPDATE fotografia
	SET username_autore = NULL
	WHERE username_autore= OLD.username AND condivisa = TRUE AND EXISTS (
		SELECT * FROM tag_utente
		WHERE tag_utente.id_foto = fotografia.id_foto AND tag_utente.username<>fotografia.username_autore	
	);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER save_tagphoto_trigger
BEFORE DELETE ON utente
FOR EACH ROW
EXECUTE FUNCTION save_tagphoto();

---------------------------------------------------------------------------------------------------------------------------------------------
-- Per non avere foto non presenti con nessun autore, possiamo poi mettere in java un avviso che quando un utente elimina la foto dalla collezione
-- lo avvisa che essa sarà eliminata per sempre, anche se magari contiene tag_utente, poichè non possedendo autore, non rispetterebbe il vincolo di autore

-- Quando un utente elimina una foto da una collezione o da un video, controlla se quella fotografia ha l'username_autore "NULL"
-- e se è presente in altre collezioni o video, nel caso non è presente in nessun video o collezione, elimina la fotografia
---------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION check_and_delete_photo() RETURNS TRIGGER AS $$
DECLARE
    count_collection INTEGER;
    count_frame INTEGER;
BEGIN
    -- Verifica se la fotografia è presente in una collezione
    SELECT COUNT(*) INTO count_collection
    FROM contenuto
    WHERE id_foto = OLD.id_foto;
    
    -- Verifica se la fotografia è presente in un video
    SELECT COUNT(*) INTO count_frame
    FROM frame
    WHERE id_foto = OLD.id_foto;
    
    -- Se la fotografia non è presente in nessuna collezione o video, la elimina
    IF ((SELECT username_autore FROM fotografia WHERE id_foto = OLD.id_foto) IS NULL AND count_collection = 0 AND count_frame = 0) THEN
        DELETE FROM fotografia WHERE id_foto = OLD.id_foto;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_and_delete_photo_trigger_content
AFTER DELETE ON contenuto
FOR EACH ROW
EXECUTE PROCEDURE check_and_delete_photo();

CREATE TRIGGER check_and_delete_photo_trigger_frame
AFTER DELETE ON frame
FOR EACH ROW
EXECUTE PROCEDURE check_and_delete_photo();



---------------------------------------------------------------------------------------------------------------------------------------------
-- Trigger che riordina i frame all'interno di un video dopo l'eliminazione di un frame
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION riordina_frame() RETURNS TRIGGER AS $$
BEGIN
    -- Riduci l'ordine dei frame successivi a quello eliminato
    UPDATE frame
    SET ordine = ordine - 1
    WHERE id_video = OLD.id_video AND ordine > OLD.ordine;
    
    RETURN NULL; -- il valore di ritorno non è rilevante per un trigger AFTER DELETE
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER riordina_frame_trigger
AFTER DELETE ON frame
FOR EACH ROW EXECUTE FUNCTION riordina_frame();

---------------------------------------------------------------------------------------------------------------------------------------------
-- Trigger che vieta ad un amministatore di eliminare altri amministratori di sistema
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION verify_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica che l'utente da eliminare non sia un admin
    IF OLD.admin = TRUE AND (SELECT COUNT(*) FROM utente WHERE admin = true) = 1 THEN
        RAISE EXCEPTION 'Non è possibile eliminare l unico utente amministratore';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verify_admin_trigger
BEFORE DELETE ON utente
FOR EACH ROW
EXECUTE FUNCTION verify_admin();

---------------------------------------------------------------------------------------------------------------------------------------------
-- Trigger che impedisce ad un'utente di inserire all'interno di una Galleria delle
-- Fotografie  private se non è l'autore di esse 
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION controllo_autore() RETURNS TRIGGER AS $$
DECLARE
proprietario_foto VARCHAR;
proprietario_collezione VARCHAR;
BEGIN
	SELECT username_autore INTO proprietario_foto FROM fotografia WHERE id_foto=NEW.id_foto;
	SELECT username INTO proprietario_collezione FROM collezione WHERE id_collezione=NEW.id_collezione;
    IF NOT EXISTS (SELECT * FROM fotografia WHERE id_foto = NEW.id_foto AND ((condivisa = true) OR (proprietario_foto = proprietario_collezione))) THEN
        RAISE EXCEPTION 'Non sei autorizzato ad utilizzare questa foto';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


	CREATE TRIGGER inserimento_Galleria
	BEFORE INSERT ON Contenuto
	FOR EACH ROW
	EXECUTE FUNCTION controllo_autore();


---------------------------------------------------------------------------------------------------------------------------------------------
--Trigger che impedisce ad un'utente che di utilizzare foto private se non ne è l'autore nei video
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION controllo_autore_video() RETURNS TRIGGER AS $$
DECLARE
proprietario_foto VARCHAR;
proprietario_video VARCHAR;
BEGIN
	SELECT username_autore INTO proprietario_foto FROM fotografia WHERE id_foto=NEW.id_foto;
	SELECT autore INTO proprietario_video FROM video WHERE id_video=NEW.id_video;
    IF NOT EXISTS (SELECT * FROM fotografia WHERE id_foto = NEW.id_foto AND ((condivisa = true) OR (proprietario_foto = proprietario_video))) THEN
        RAISE EXCEPTION 'Non sei autorizzato ad utilizzare questa foto';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

	CREATE TRIGGER inserimento_frame
	BEFORE INSERT ON frame
	FOR EACH ROW
	EXECUTE FUNCTION controllo_autore_video();
