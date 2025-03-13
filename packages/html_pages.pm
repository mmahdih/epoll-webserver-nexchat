package html_pages;

use strict;
use warnings;


sub get_html_page {
    my ($page , $my_username, $receiver_username) = @_;

    my $html_page;
    if ($page eq "index"){
        $html_page = <<HTML;
<!DOCTYPE html>
<html>
<head>
    <title>Websocket Server</title>
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
</head>
<body>
    <h1>Websocket Server</h1>
    <input type="text" id="message" placeholder="Enter message">
    <button id="send">Send</button>
    <input id="slider" type="range">
    <
</body>
</html>
HTML
#     } elsif ($page eq "chat") {
#         $html_page = <<HTML;
# <!DOCTYPE html>
# <html lang="en">
# <head>
#     <meta charset="UTF-8">
#     <meta name="viewport" content="width=device-width, initial-scale=1.0">
#     <title>Chat App</title>
#     <script src="https://cdn.tailwindcss.com"></script>
#     <script>
#         document.addEventListener("DOMContentLoaded", function () {
#             const chatBox = document.getElementById("chat-box");
#             const messageInput = document.getElementById("message");
#             const sendButton = document.getElementById("send");
#             const sender = document.getElementById("display-name");
            
#             const ws = new WebSocket("ws://10.31.1.1:8080/api/messages");

#             ws.onopen = () => {
#                 console.log("Connected to server");
#                 let data = {
#                     my_username: "$my_username",
#                     friend_username: "$receiver_username"
#                 };
#                 ws.send(JSON.stringify(data));
#                 ws.send("ping");
#             };

#             ws.onmessage = (event) => {

#                 if (event.data === "pong") {
#                     const timeout = setTimeout(() => {
#                         ws.send("ping");
#                     }, 1000);
                    
#                 } else {
#                     let data = JSON.parse(event.data);
#                     let sender = data.name;
#                     let message = data.message;

#                     const messageElement = document.createElement("div");
#                     messageElement.className = "p-2 bg-gray-200 rounded-lg mb-2 self-start";
#                     messageElement.textContent = message;
#                     chatBox.appendChild(messageElement);
#                     chatBox.scrollTop = chatBox.scrollHeight;

#                     console.log(sender);
#                     const nameElement = document.createElement("div");
#                     nameElement.className = "text-xs text-gray-500 mb-2 self-start";
#                     nameElement.textContent = sender;
#                     chatBox.appendChild(nameElement);
#                     chatBox.scrollTop = chatBox.scrollHeight;
#                 }
#             };

#             ws.onerror = (error) => {
#                 console.error(error)
#                 setTimeout(() => {
#                     console.log("Attempting to reconnect...");
#                     ws = new WebSocket("ws://10.31.1.1:8080/api/messages");
#                 }, 1000);
#             };


#             ws.onclose = () => {
#                 console.log("Connection closed");
#                 setTimeout(() => {
#                     console.log("Attempting to reconnect...");
#                     ws = new WebSocket("ws://10.31.1.1:8080/api/messages");
#                 }, 1000);
#             }

#             messageInput.addEventListener("keyup", (event) => {
#                 if (event.key === "Enter") {
#                     sendButton.click();
#                 }
#             });



#             sendButton.addEventListener("click", () => {
#                 let message = messageInput.value.trim();
#                 let name = "$my_username";
#                 let data = {
#                     sender_username : "$my_username",
#                     receiver_username : "$receiver_username",
#                     message : message,
#                     timestamp : Date.now()
#                 };
#                 let jsonData = JSON.stringify(data);


#                 if (message) {
#                     ws.send(jsonData);
#                     const userMessage = document.createElement("div");
#                     userMessage.className = "p-2 bg-blue-500 text-white rounded-lg self-end";
#                     userMessage.textContent = message;
#                     chatBox.appendChild(userMessage);
#                     chatBox.scrollTop = chatBox.scrollHeight;
#                     messageInput.value = "";

#                     let name = "$my_username";
#                     console.log(name);
#                     const nameElement = document.createElement("div");
#                     nameElement.className = "text-xs text-gray-500 mb-2 self-end";
#                     nameElement.textContent = name;
#                     chatBox.appendChild(nameElement);
#                     chatBox.scrollTop = chatBox.scrollHeight;
#                 }
#             });

#             const pageAccessedByReload = (
#             (window.performance.navigation && window.performance.navigation.type === 1) ||
#                 window.performance
#                 .getEntriesByType('navigation')
#                 .map((nav) => nav.type)
#                 .includes('reload')
#             );

#             if (pageAccessedByReload) {
#                 window.location.href = "/";
#             }
#         });
#     </script>
# </head>
# <body class="flex items-center justify-center h-screen bg-gray-100">
#     <div class="w-full max-w-lg bg-white shadow-lg rounded-lg p-6 flex flex-col">
#         <h1 class="text-2xl font-bold mb-4">Chat App</h1>
#         <div class="flex flex-row justify-between items-center mb-4">
#             <div class="flex flex-col items-center">
#                 <h2 class="font-bold">You</h2>
#                 <h2 id="display-name" class="text-lg">$my_username</h2>
#             </div>
#             <div class="flex flex-col items-center">
#                 <h2 class="font-bold">Your Friend</h2>
#                 <h2 id="friend-name" class="text-lg">$receiver_username</h2>
#             </div>
#         </div>
#         <div id="chat-box" class="flex flex-col space-y-2 overflow-y-auto h-64 p-2 border rounded-lg bg-gray-50"></div>
#         <div class="flex mt-4 space-x-2">
            
#             <input id="message" type="text" placeholder="Type a message..." class="flex-1 p-2 border rounded-lg">
#             <button id="send" class="px-4 py-2 bg-blue-500 text-white rounded-lg">Send</button>
#         </div>
#     </div>
# </body>
# </html>
# HTML

    } elsif ($page eq "chat") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>NexChat</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body class="bg-gray-100 h-screen flex flex-col items-center justify-center">
    <!-- Logo -->
    <div class="flex items-center space-x-3 mb-6">
      <div class="bg-gradient-to-r from-indigo-500 to-purple-500 p-3 rounded-full shadow-lg">
        <span class="text-white text-3xl font-bold"> N </span>
      </div>
      <h1 class="text-4xl font-bold text-gray-800">NexChat</h1>
    </div>
    

    <div class="flex w-full max-w-4xl h-[600px] bg-white rounded-lg shadow-lg overflow-hidden">
      <!-- Friends List -->
      <div class="w-1/3 bg-gray-200 p-4 overflow-y-auto">
        <h2 class="text-xl font-semibold mb-4">Friends</h2>
        <ul id="friendsList">
        <!--  <li class="friend p-3 bg-gray-300 rounded-lg mb-2 cursor-pointer hover:bg-white" data-name="Friend 1">Friend 1</li> -->
        </ul>
      </div>

      <!-- Chat Messages -->
      <div class="w-2/3 flex flex-col p-4">
        <h2 class="text-xl font-semibold mb-4">Chat with</h2>
        <h3 id="chatWith" class="text-2xl font-semibold mb-4"></h3>
        <div class="messages-container flex-1 overflow-y-auto space-y-2"></div>
        
        <!-- Message Input -->
        <div class="mt-4 flex items-center space-x-2">
        <input type="file" id="add-file" class="hidden" />
        <label for="add-file" class="ml-2 bg-indigo-500 text-white px-4 py-2 rounded-lg hover:bg-indigo-600">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
        </label>
          <input id="messageInput" type="text" class="flex-1 p-2 border border-gray-300 rounded-lg focus:outline-none" placeholder="Type a message..." />
          <button id="sendMessage" class="ml-2 bg-indigo-500 text-white px-4 py-2 rounded-lg hover:bg-indigo-600">Send</button>
        </div>
      </div>
    </div>


    <script>
    const messagesContainer = document.querySelector('.messages-container');
    const messageInput = document.getElementById('messageInput');
    const sendMessageButton = document.getElementById('sendMessage');
    const friendsList = document.getElementById('friendsList');
    let users = [];
    let chat_id;

    // Connect to WebSocket server
    const ws = new WebSocket("ws://" + window.location.host + "/ws");

    console.log("Connecting to server at " + window.location.href );
    
    function appendToURL(key, value) {
        let url = new URL(window.location.href);
        url.searchParams.set(key, value); // Add or update query param
        window.history.pushState({}, "", url);
    }

    


 
    ws.onopen = () => {
        console.log("Connected to server");
        ws.send(JSON.stringify({ action: "ping" }));
        ws.send(JSON.stringify({ action: "get_users" })); // Request user list
    };

    ws.onclose = () => console.log("Disconnected from server");
    ws.onerror = (error) => console.error("WebSocket error:", error);

    ws.onmessage = (event) => {
        try {
            let received_data = JSON.parse(event.data);

            
            if (received_data.action === "users_list") {
                users = received_data.users;
                
                    // ws.send(JSON.stringify({ action: "get_users" }));
                    console.log("Users list is:" + users);
                
                console.log("test");
                renderFriendsList();
            } else if (received_data.action === "new_message") {
                displayMessage(received_data.message, "friend");
            } else if (received_data.action === "pong") {
                const timeout = setTimeout(() => {
                ws.send(JSON.stringify({ action: "ping" }));
                }, 1000);
            } else if (received_data.action === "chat_id") {
                chat_id = received_data.chat_id;
                console.log("Chat ID:", chat_id);
            } else if (received_data.action === "messages") {
                console.log("Received messages:", received_data.messages);
                let usernameCookie = document.cookie.split("; ").find(row => row.startsWith("username="));
                let sender_username = usernameCookie ? usernameCookie.split("=")[1] : null;
                if (!sender_username) {
                    console.error("Username not found in cookies.");
                }
                received_data.messages.forEach(message => {
                    if (message.sender_username === sender_username) {
                        displayMessage(message.content, "own");
                    } else {
                        displayMessage(message.content, "friend");
                    }
                });
            }
        } catch (error) {
            console.error("Error parsing WebSocket message:", error);
        }
    };

    // Function to render friends list dynamically
    function renderFriendsList() {
        friendsList.innerHTML = ""; // Clear existing friends list
        users.forEach(user => {
            
            const friend = document.createElement('li');
            friend.classList.add('friend', 'p-3', 'bg-gray-300', 'rounded-lg', 'mb-2', 'cursor-pointer', 'hover:bg-white');
            friend.textContent = user.display_name;
            friend.setAttribute('data-name', user.display_name);
            friendsList.appendChild(friend);
            
        });
    }

    

    // Event delegation for friend selection
    friendsList.addEventListener("click", (event) => {
        // ask server to create a chat and send the chat id
        // get the user id from cookies
        let usernameCookie = document.cookie.split("; ").find(row => row.startsWith("username="));
        let sender_username = usernameCookie ? usernameCookie.split("=")[1] : null;
        if (!sender_username) {
            console.error("Username not found in cookies.");
        }

        let chat_with = document.getElementById('chatWith');
        chat_with.textContent = event.target.getAttribute("data-name");

        appendToURL("username", event.target.getAttribute("data-name"));
        


        const messageData = {
            action: "get_chat_id",
            receiver_id: users.find(user => user.display_name === event.target.getAttribute("data-name")).user_id,
            sender_username: sender_username
        }
        console.log(messageData);
        ws.send(JSON.stringify(messageData));

        if (typeof chat_id !== 'undefined') {
            if (event.target.closest(".friend")) {
            document.querySelectorAll(".friend").forEach(f => f.classList.remove("bg-white"));
            event.target.classList.add("bg-white");

            const friendName = event.target.getAttribute("data-name");
            console.log("Selected friend:", friendName);
            console.log("Chat ID:", chat_id);

            messagesContainer.innerHTML = ""; // Clear messages when switching chat

           


            const messageData = {
                action: "get_messages",
                chat_id: chat_id
            }
            ws.send(JSON.stringify(messageData));

            // messages.forEach((message) => {
            //     displayMessage(message.text, message.type);
            // });


        } else if (!event.target.closest(".friend")) {
            console.log("Clicked element is not a friend.");
            return;
        }
        } else {
            console.log("No chat selected.");
        }
    });

    messageInput.addEventListener("keypress", (event) => {
        if (event.key === "Enter") {
            sendMessageButton.click();
        }
    });


    // Send message
    sendMessageButton.addEventListener("click", () => {
        const messageText = messageInput.value.trim();
        console.log("Sending message:", messageText);
        if (!messageText) return;

        let sender_username = document.cookie.split("; ").find(row => row.startsWith("username=")).split("=")[1];

        if (!chat_id) {
            console.error("No chat ID available. Cannot send message.");
            return;
        }


        const messageData = {
            action: "send_message",
            chat_id: chat_id, // Replace with actual selected friend
            message: messageText,
            sender_username: sender_username
        };
        console.log("Message data:", messageData);
        ws.send(JSON.stringify(messageData));
        displayMessage(messageText, "own");
        messageInput.value = "";
    });

    // Function to display messages
    function displayMessage(text, type) {
        const messageElement = document.createElement("div");
        messageElement.classList.add("p-3", "rounded-lg", "w-fit", "max-w-xs", "mb-2");

        if (type === "own") {
            messageElement.classList.add("bg-indigo-500", "text-white", "ml-auto");
        } else {
            messageElement.classList.add("bg-gray-300", "text-gray-800", "mr-auto");
        }

        messageElement.textContent = text;
        messagesContainer.appendChild(messageElement);
        messagesContainer.scrollTop = messagesContainer.scrollHeight; // Auto-scroll



        
    }
</script>

   
  </body>
</html>
HTML
    



    } elsif ($page eq "home") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">  
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .tools {
            display: none;
        }
    </style>
    <script>
        const tools = document.querySelector(".tools");
        if (localStorage.getItem("name")) {
            tools.style.display = "flex";
        } else {
            tools.style.display = "none";
        }
    </script>
</head>
<body class="bg-gray-200 text-center">
    <div class="bg-gray-800 text-white p-6">
        <h1 class="text-3xl mb-2">Home</h1>
        <ul class="flex justify-center space-x-4">
            <li><a href="/login" class="hover:text-yellow-300">Login</a></li>
            <li><a href="/register" class="hover:text-yellow-300">Register</a></li>
            <div class="tools flex justify-center space-x-4">

                <li><a href="/profile" class="hover:text-yellow-300">Profile</a></li>
                <li><a href="/chat" class="hover:text-yellow-300">Chat</a></li>
                <li><a href="/friends" class="hover:text-yellow-300">Friends</a></li>
            </div>
        </ul>
        <form action="/api/auth/logout" method="post" class="flex flex-col items-center mt-4">
                <button type="submit" class="mb-4 mt-4 bg-red-500 text-white px-4 py-2  rounded-lg">Logout</button>
        </form>
    </div>
</body>
</html>
HTML

    } elsif ($page eq "menu") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Menu</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-200 text-center">
    <div class="bg-gray-800 text-white p-6">
        <h1 class="text-3xl mb-2">Menu</h1>
        <ul class="flex justify-center space-x-4">
            <li><a href="/" class="hover:text-yellow-300">Home</a></li>
            <li><a href="/chat" class="hover:text-yellow-300">Chat</a></li>
        </ul>
    </div>
</body>
</html>

HTML
    
    } elsif ($page eq "profile") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Profile</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="font-sans bg-gray-200 text-center">
    <div class="bg-gray-800 text-white p-6">
        <h1 class="text-3xl mb-2">Profile</h1>
        <p class="text-lg">Welcome to your profile page.</p>
    </div>

    <div class="mt-6">
        <form action="/set_profile" method="post" class="bg-white p-6 shadow-md rounded-lg max-w-lg mx-auto" >
            <div class="grid gap-6 mb-6 md:grid-cols-2">
                <div class="mb-4 flex flex-col flex flex-col">
                    <label for="first-name" class="block text-gray-700 text-sm font-bold mb-2 focus:ring-blue-500 focus:border-blue-500 self-start">First Name:</label>
                    <input type="text" id="first-name" name="firstname" placeholder="John" required class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5">
                </div>
                <div class="mb-4 flex flex-col">
                    <label for="last-name" class="block text-gray-700 text-sm font-bold mb-2 focus:ring-blue-500 focus:border-blue-500 self-start">Last Name:</label>
                    <input type="text" id="last-name" name="lastname" required placeholder="Doe" class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5">
                </div>
                <div class="mb-4 flex flex-col">
                    <label for="display-name" class="block text-gray-700 text-sm font-bold mb-2 focus:ring-blue-500 focus:border-blue-500 self-start">Display Name:</label>
                    <div class="flex">
                        <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border rounded-e-0 border-gray-300 border-e-0 rounded-s-md">
                            <svg class="w-4 h-4 text-gray-500 dark:text-gray-400" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M10 0a10 10 0 1 0 10 10A10.011 10.011 0 0 0 10 0Zm0 5a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm0 13a8.949 8.949 0 0 1-4.951-1.488A3.987 3.987 0 0 1 9 13h2a3.987 3.987 0 0 1 3.951 3.512A8.949 8.949 0 0 1 10 18Z"/>
                            </svg>
                        </span>
                        <input type="text" id="display-name" name="display_name" class="rounded-none rounded-e-lg bg-gray-50 border text-gray-900 focus:ring-blue-500 focus:border-blue-500 block flex-1 min-w-0 w-full text-sm border-gray-300 p-2.5  " placeholder="John Doe">
                        </div>
                </div>
                <div class="mb-4 flex flex-col">
                    <label for="name" class="block text-gray-700 text-sm font-bold mb-2 focus:ring-blue-500 focus:border-blue-500 self-start">Email:</label>
                    <div class="relative mb-6">
                        <div class="absolute inset-y-0 start-0 flex items-center ps-3.5 pointer-events-none">
                            <svg class="w-4 h-4 text-gray-500 dark:text-gray-400" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 16">
                                <path d="m10.036 8.278 9.258-7.79A1.979 1.979 0 0 0 18 0H2A1.987 1.987 0 0 0 .641.541l9.395 7.737Z"/>
                                <path d="M11.241 9.817c-.36.275-.801.425-1.255.427-.428 0-.845-.138-1.187-.395L0 2.6V14a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V2.5l-8.759 7.317Z"/>
                            </svg>
                        </div>
                          <input type="text" id="input-group-1" name="email" class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full ps-10 p-2.5" placeholder="john.doe\@example.com">
                    </div>
                </div>
                <div class="mb-4 flex flex-col">
                    <label for="password" class="block text-gray-700 text-sm font-bold mb-2 focus:ring-blue-500 focus:border-blue-500 self-start">Password:</label>
                    <input type="password" id="password" name="password" required placeholder="Password" class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5">
                </div>
                <div class="mb-4 flex flex-col">
                    <label for="confirm-password" class="block text-gray-700 text-sm font-bold mb-2 focus:ring-blue-500 focus:border-blue-500 self-start">Confirm Password:</label>
                    <input type="password" id="confirm-password" name="confirm-password" required placeholder="Confirm Password" required class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5">
                </div>

            </div>
            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline">Save</button>
        </form>
        
    </div>
</body>
</html>
HTML
    
    } elsif ($page eq "login") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
    
</head>
<body class="bg-gray-200 text-center">
    <div class="bg-gray-800 text-white p-6">
        <h1 class="text-3xl mb-2">Login</h1>
        <form action="/api/auth/login" method="POST">
            <input type="text" name="username" placeholder="Username" class="mb-4 p-2 w-full text-black rounded">
            <input type="password" name="password" placeholder="Password" class="mb-4 p-2 w-full text-black rounded">
            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Login</button>
        </form>
    </div>
</body>
</html>
HTML


    } elsif ($page eq "register") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-200 text-center">
    <div class="bg-gray-800 text-white p-6">
        <h1 class="text-3xl mb-2">Register</h1>
        <form action="/api/auth/register" method="POST">
            <input type="text" name="fullname" placeholder="Full Name" class="mb-4 p-2 w-full text-black rounded">
            <input type="text" name="username" placeholder="Username" class="mb-4 p-2 w-full text-black rounded">
            <input type="text" name="display_name" placeholder="Display Name" class="mb-4 p-2 w-full text-black rounded">
            <input type="text" name="email" placeholder="Email" class="mb-4 p-2 w-full text-black rounded">
            <input type="password" name="password" placeholder="Password" class="mb-4 p-2 w-full text-black rounded">
            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Register</button>
        </form>
    </div>
</body>
</html>
HTML
    
    } elsif ($page eq "friends") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Friends</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#007bff',
                        secondary: '#6c757d',
                        success: '#28a745',
                        danger: '#dc3545',
                        warning: '#ffc107',
                        info: '#17a2b8',
                    },
                },
            },
        }

        const socket = new WebSocket('ws://localhost:8080/api/friends');

        socket.onopen = function(event) {
            console.log('WebSocket connection opened');
            socket.send("ping");
        }


        socket.onmessage = function(event) {
            if (event.data === "pong") {
                setTimeout(() => {
                    socket.send("ping");
                }, 1000);
            } else {
                try {
                    const data = JSON.parse(event.data);

                    if (!Array.isArray(data)) {
                        console.error("Expected an array but got:", data);
                        return;
                    }

                    const friendsContainer = document.getElementById('friends-container');
                    friendsContainer.innerHTML = ''; 

                    data.forEach((friend) => {
                        if (!friend.user_id || !friend.display_name || !friend.username) {
                            console.error("Invalid friend object:", friend);
                            return;
                        }

                        let user_id = friend.user_id;
                        let display_name = friend.display_name;
                        let username = friend.username;


                        const friendDiv = document.createElement('div');
                        friendDiv.classList.add('bg-white', 'rounded-lg', 'shadow', 'p-4', 'mb-4', 'flex', 'flex-col', 'items-center', "hover:bg-gray-100", "cursor-pointer", "transition", "duration-300", "ease-in-out");
                        friendDiv.addEventListener('click', () => {
                            window.location.href = '/chat?username=' + username;
                        });
                        const display_nameElement = document.createElement('h1');
                        display_nameElement.classList.add('text-2xl', 'font-bold', 'mb-2');
                        display_nameElement.textContent = display_name;
                        friendDiv.appendChild(display_nameElement);

                        const usernameElement = document.createElement('p');
                        usernameElement.classList.add('text-gray-600');
                        usernameElement.textContent = username;
                        friendDiv.appendChild(usernameElement);

                        const user_idElement = document.createElement('p');
                        user_idElement.classList.add('text-gray-600');
                        user_idElement.textContent = user_id;
                        friendDiv.appendChild(user_idElement);


                        friendsContainer.appendChild(friendDiv);
                    });
                } catch (error) {
                    console.error("Error parsing WebSocket message:", error);
                }
            }
        };


        function addFriend(user_id, display_name, username) {
            const friend = { user_id: user_id, display_name: display_name, username: username };
            socket.send(JSON.stringify(friend));
            console.log("Friend added:", friend);
        }

        function removeFriend(user_id) {
            const friend = { user_id: user_id };
            socket.send(JSON.stringify(friend));
            console.log("Friend removed:", friend);
        }

        function sendFriendRequest(user_id) {
            const friend = { user_id: user_id };
            socket.send(JSON.stringify(friend));
            console.log("Friend request sent:", friend);
        }

        function acceptFriendRequest(user_id) {
            const friend = { user_id: user_id };
            socket.send(JSON.stringify(friend));
            console.log("Friend request accepted:", friend);
        }

        function rejectFriendRequest(user_id) {
            const friend = { user_id: user_id };
            socket.send(JSON.stringify(friend));
            console.log("Friend request rejected:", friend);
        }

        function sendMessage(user_id, message) {
            const messageData = { user_id: user_id, message: message };
            socket.send(JSON.stringify(messageData));
            console.log("Message sent:", messageData);
        }


            
        

        socket.onerror = function(event) {
            console.error('WebSocket error:', event);
        }

        socket.onclose = function(event) {
            console.log('WebSocket connection closed');
        }
    </script>
</head>
<body class="bg-gray-200 text-center">
    <div class="bg-gray-800 text-white p-6">
        <h1 class="text-3xl mb-2">Friends</h1>
    </div>
    <div id="friend-search" class="bg-white rounded-lg shadow p-4">
        <form action="/api/friends" method="POST" class="mb-4">
            <input type="text" name="name" placeholder="Search for a friend" class="mb-4 p-2 w-full text-black rounded-lg border-2 border-gray-300">
            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg">Search</button>
        </form>
        <div id="friends-list" class="bg-white rounded-lg shadow p-4">
            <div id="friends-container" class="bg-white rounded-lg shadow p-4 flex flex-col gap-4"></div>
        </div>
    </div>
</body>
</html>
HTML

    } elsif ($page eq "error") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-200 text-center">
    <div class="bg-gray-800 text-white p-6">
        <h1 class="text-3xl mb-2">Error</h1>
        <p class="text-lg mb-4">This Profile already exists.</p>
        <a href="/" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mt-4">Go Home</a>
    </div>
</body>
</html>
HTML
    
    } elsif ($page eq "404") {
        $html_page = <<HTML;
<!DOCTYPE html>
<html class="scroll-smooth">
<head>
    <title>404 - Not Found</title>
    <link href="https://unpkg.com/tailwindcss@^2/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-100 h-screen flex items-center justify-center">
    <div class="bg-white rounded-lg shadow-lg p-8 md:p-12 w-full md:w-1/2 lg:w-1/3">
        <h1 class="text-6xl font-bold text-red-600 mb-4">404</h1>
        <p class="text-2xl text-gray-700 mb-8">The page you are looking for could not be found.</p>
        <a href="/" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-full">Go Home</a>
    </div>
</body>
</html>
HTML
    }
    return $html_page;
}



sub get_favicon {
    open my $icon, '<', '/home/lapdev/Mein/epoll-webserver-nexchat/bilder/favicon.ico' or die $!;
    binmode $icon;

    my $icon_data = do { local $/; <$icon> };
    close $icon;

    return $icon_data;
}

1;