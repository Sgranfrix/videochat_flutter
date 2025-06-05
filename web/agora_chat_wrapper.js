window.agoraChat = {
    client: null,

    initClient: function(appKey) {
        this.client = new WebIM.connection({
            appKey: appKey,
            isMultiLoginSessions: true,
            https: true
        });
    },

    login: function(userId, token) {
        return this.client.open({
            user: userId,
            accessToken: token
        });
    },

   sendMessage : function(to, message) {
        const msg = new WebIM.message('txt', Date.now().toString());
        msg.set({
            msg: message,
            to: to,
            chatType: 'single',
            success: function() {
                console.log('Message sent successfully');
            },
            fail: function(e) {
                console.error('Send failed', e);
            }
        });
        window.agoraChat.client.send(msg.body);
    }



};
