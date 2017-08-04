# Xorro P2P

Xorro P2P is a Ruby implementation of a browser-based peer-to-peer networking client.

## Getting Started

### Install ngrok
Ngrok is a tool that allows you to expose a local server behind a NAT or firewall to the internet.

Install ngrok if you don't already have it on your system. [Get ngrok here.](https://ngrok.com/download)

Once ngrok is installed, create an account and go to your dashboard on www.ngrok.com to retrieve your auth token. This is not necessary, but highly recommended because it will allow you to make more requests before hitting ngrok's request limit on a free account.

### Launching the App
After downloading the repository and running `bundle install`, run the following command from the project folder:
```
bin/launch_public.sh
```

In your browser, go to `http://localhost/9999`.

You now have access to your admin panel, where you can upload, distribute and download files.
