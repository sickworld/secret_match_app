# secret_match_app

## Admin-Billboard

Angemeldete Administratoren können das WordPress-Billboard über **Billboard Vollbild** direkt in der App öffnen. Die App fordert dafür über `POST /wp-json/secretmatch/v1/admin/billboard-access` einen kurzlebigen Einmal-Link an; Admin- oder Billboard-Passwörter werden nicht in der WebView-URL übertragen.

Der Admin-Login liefert ein zeitlich begrenztes Bearer-Token. Es bleibt nur im Arbeitsspeicher der App, wird bei jedem geschützten Admin-Aufruf mitgesendet und beim Abmelden serverseitig widerrufen.
