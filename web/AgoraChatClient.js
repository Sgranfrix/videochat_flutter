// Assicurati che AgoraChat sia già disponibile nel contesto globale
(function () {

    function AgoraChatClient(appKey) {
        this.appKey = appKey;
        this.connection = null;
    }

    AgoraChatClient.prototype.init = function () {
        this.connection = new AgoraChat.connection({
            appKey: this.appKey
        });

        this.connection.addEventHandler('default', {
            onConnected: function () {
                console.log('✅ Connesso ad Agora Chat');
            },
            onDisconnected: function () {
                console.log('🔌 Disconnesso da Agora Chat');
            },
            onTextMessage: function (message) {
                console.log('📩 Messaggio ricevuto:', message);
            },
            onError: function (error) {
                console.error('❌ Errore:', error);
            },
        });
    };

    AgoraChatClient.prototype.joinGroup = async function (groupId) {
        if (!this.connection) {
            console.error('⚠️ Connessione non inizializzata. Chiama init() prima di joinGroup().');
            return;
        }

        try {
            await this.connection.joinGroup({ groupId: groupId });
            console.log(`✅ Richiesta per unirsi al gruppo ${groupId} inviata con successo`);
        } catch (error) {
            console.error(`❌ Errore durante la richiesta di unione al gruppo ${groupId}:`, error);
        }
    };

    AgoraChatClient.prototype.login = async function (userId, accessToken) {
        if (!this.connection) {
            console.error('⚠️ Connessione non inizializzata. Chiama init() prima di login().');
            return;
        }

        try {
            await this.connection.open({
                user: userId,
                accessToken: accessToken,
            });
            console.log('🔐 Login effettuato con successo');
        } catch (error) {
            console.error('❌ Errore durante il login:', error);
        }
    };

    AgoraChatClient.prototype.sendGroupMessage = async function (groupId, messageContent) {
        if (!this.connection) {
            console.error('⚠️ Connessione non inizializzata. Chiama init() prima di inviare messaggi.');
            return;
        }

        const message = window.AgoraChat.message.create({
            type: 'txt',
            chatType: 'groupChat',
            to: groupId,
            msg: messageContent,
        });

        try {
            await this.connection.send(message);
            console.log('✅ Messaggio inviato al gruppo', groupId);
        } catch (error) {
            console.error('❌ Errore durante l\'invio del messaggio al gruppo:', error);
        }
    };

    AgoraChatClient.prototype.logout = function () {
        if (this.connection) {
            this.connection.close();
            console.log('👋 Disconnesso da Agora Chat');
        }
    };

    // Esporta la classe nel contesto globale
    window.AgoraChatClient = AgoraChatClient;
})();

// Esportare la classe
window.AgoraChatClient = AgoraChatClient;
