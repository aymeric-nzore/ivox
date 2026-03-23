# IVOX Frontend (Flutter)

Application mobile Flutter pour IVOX (chat temps reel, boutique, profil, notifications).

## Installation rapide

```bash
cd frontend/ivox
flutter pub get
flutter run
```

## Architecture chat temps reel

### Couches

1. UI: `lib/features/chat/presentation/chat_page.dart`
2. Service socket/API: `lib/features/chat/services/chat_services.dart`
3. Notifications locales in-app: `lib/core/services/notification_service.dart`
4. Push hors app (FCM token): `lib/core/services/fcm_token_service.dart`

### Source des messages

L'envoi de message passe par REST (`POST /api/messages`) puis le backend diffuse les events socket `message_new` et `message_sent`.

## Typing event: fonctionnement

### Emission côté Flutter

Dans `chat_page.dart`:

1. Quand l'utilisateur commence a taper (`TextField.onChanged`) et que le champ devient non vide:
	 - `sendTypingStart(receiverId)`
2. Quand le champ devient vide:
	 - `sendTypingStop(receiverId)`
3. Juste avant envoi du message:
	 - `sendTypingStop(receiverId)` pour fermer l'etat typing
4. Au `dispose()` de la page:
	 - `sendTypingStop(receiverId)` si necessaire

### Reception côté Flutter

Dans `chat_services.dart`:

1. Ecoute socket `typing_start` et `typing_stop`
2. Mise a jour d'un map interne `_typingByUser`
3. Exposition d'un stream `userTypingStream(userId)`

Dans `chat_page.dart`:

1. Ecoute `userTypingStream(receiverId)`
2. Affiche `En train d'ecrire...` dans le header quand `true`
3. Sinon affiche `En ligne` ou `Vu ...`

## Contrat payloads (frontend)

### `typing_start` (serveur → client)
```json
{
	"fromUserId": "507f1f77bcf86cd799439011"
}
```

### `typing_stop` (serveur → client)
```json
{
	"fromUserId": "507f1f77bcf86cd799439011"
}
```

### `message_new` / `message_sent`
```json
{
	"messageId": "b3d5f8a0-...",
	"sender": "507f1f77bcf86cd799439011",
	"receiver": "507f1f77bcf86cd799439012",
	"message": "Salut",
	"status": "sent",
	"createdAt": "2026-03-23T12:34:56.000Z"
}
```

### `app_notification` (chat)
```json
{
	"type": "chat_message",
	"messageId": "b3d5f8a0-...",
	"fromUserId": "507f1f77bcf86cd799439011",
	"preview": "Salut",
	"createdAt": "2026-03-23T12:34:56.000Z"
}
```

### `user_presence`
```json
{
	"userId": "507f1f77bcf86cd799439011",
	"status": "online",
	"lastSeen": "2026-03-23T12:34:56.000Z"
}
```

## Notifications

### 1) In-app (app ouverte)

`notification_service.dart` ecoute `appNotifications` depuis `ChatServices` et affiche des notifications locales (friend request, message, nouvelle musique).

### 2) Hors app (push)

`fcm_token_service.dart`:

1. Initialise Firebase
2. Recupere le token FCM
3. Enregistre le token via `POST /api/auth/fcm-token`
4. Sync a chaque login/register/google login
5. Supprime le token au logout via `DELETE /api/auth/fcm-token`

## Anti-doublon notifications

Le frontend attend un seul event par action.
Le backend a ete corrige pour emettre une seule fois vers l'union des rooms utilisateur (plus de double notifications locales simultanees).

## Debug checklist

### Typing n'apparait pas

1. Verifier que les 2 users sont connectes socket (`user_join` emis)
2. Verifier que `typing_start`/`typing_stop` arrivent dans les logs backend
3. Verifier que `chat_page.dart` ecoute `userTypingStream(receiverId)`

### Notifications en double

1. Verifier que le backend contient bien l'emission unique:
	 - `io.to(id).to('user:${id}').emit(...)`
2. Verifier qu'un seul `NotificationService().initialize()` est appele au demarrage

### Push hors app ne marche pas

1. Verifier la presence d'un `fcmToken` en base pour le user
2. Verifier les variables Firebase Admin cote backend
3. Verifier permission notifications Android/iOS
