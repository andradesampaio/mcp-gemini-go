const messagesDiv = document.getElementById('messages');
const messageInput = document.getElementById('messageInput');
const sendButton = document.getElementById('sendButton');

function formatBotMessage(content) {
    let formatted = content;
    
    formatted = formatted.replace(/\n/g, '<br>');
    formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    formatted = formatted.replace(/^•\s/gm, '&bull; ');
    formatted = formatted.replace(/<br><br>/g, '<br><div style="height: 8px;"></div>');
    
    return formatted;
}

function addMessage(content, isUser = false) {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message ' + (isUser ? 'user-message' : 'bot-message');
    
    if (isUser) {
        messageDiv.textContent = content;
    } else {
        messageDiv.innerHTML = formatBotMessage(content);
    }
    
    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

function addLoadingMessage() {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message loading';
    messageDiv.id = 'loading-message';
    messageDiv.textContent = 'Pensando...';
    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
    return messageDiv;
}

function removeLoadingMessage() {
    const loading = document.getElementById('loading-message');
    if (loading) {
        loading.remove();
    }
}

async function sendMessage() {
    const message = messageInput.value.trim();
    if (!message) return;

    addMessage(message, true);
    messageInput.value = '';
    
    sendButton.disabled = true;
    messageInput.disabled = true;
    
    const loading = addLoadingMessage();

    try {
        const response = await fetch('/chat', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ message: message })
        });

        const data = await response.json();
        
        removeLoadingMessage();
        
        if (data.error) {
            addMessage('❌ Erro: ' + data.error);
        } else {
            addMessage(data.response);
        }
    } catch (error) {
        removeLoadingMessage();
        addMessage('❌ Erro de conexão: ' + error.message);
    }

    // Reabilitar input
    sendButton.disabled = false;
    messageInput.disabled = false;
    messageInput.focus();
}

document.addEventListener('DOMContentLoaded', function() {
    messageInput.focus();
});

messageInput.addEventListener('keypress', function(event) {
    if (event.key === 'Enter') {
        sendMessage();
    }
});

sendButton.addEventListener('click', sendMessage);
