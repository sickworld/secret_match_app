# secret_match_app

## Admin-Billboard

Angemeldete Administratoren können das WordPress-Billboard über **Billboard Vollbild** direkt in der App öffnen. Die App fordert dafür über `POST /wp-json/secretmatch/v1/admin/billboard-access` einen kurzlebigen Einmal-Link an; Admin- oder Billboard-Passwörter werden nicht in der WebView-URL übertragen.

Der Admin-Login liefert ein zeitlich begrenztes Bearer-Token. Es bleibt nur im Arbeitsspeicher der App, wird bei jedem geschützten Admin-Aufruf mitgesendet und beim Abmelden serverseitig widerrufen.

## Anonymes Feedback

Die Teilnehmer-App sendet Feedback über `POST /wp-json/secretmatch/v1/feedback` als JSON mit `rating` und `functionality_rating` (jeweils 1–5). Der Request nutzt eine cookiefreie, ephemere Session und enthält keine Eventnummer.

Der Server-Endpunkt muss beide Bewertungen validieren und darf Feedback weder mit Teilnehmer-Sitzungen noch mit Eventnummern verknüpfen.

Die iPhone-Admin-App lädt die anonymen Einträge über `GET /wp-json/secretmatch/v1/admin/feedback` und löscht einzelne Einträge über `DELETE /wp-json/secretmatch/v1/admin/feedback/{id}`. Beide Aufrufe erfordern das Admin-Bearer-Token.
