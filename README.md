# Godot-Multiplayer-Prototype
Overview

This project is a low-level multiplayer game prototype built in Godot 4.4 using ENet.
It explores core networking concepts such as client/server connections, state synchronization, and real-time multiplayer mechanics without relying on Godot’s high-level multiplayer API.

## Features

- Movement synchronization for multiple players
- Enemy spawning: enemies move toward players with a A* pathfinding algorithm and attack automatically
- Weapons system: players can spawn weapons and attack enemies (currently only the sword works)
- Networking: join games via IP, supporting local network and internet play using UPnP

## Purpose

The goal of this project was to experiment with low-level multiplayer mechanics, including:

- server-authoritative movement and game state
- basic player actions and combat logic
- real-time synchronization over ENet
- networking setup for both LAN and online play

## How to Run

Open the project in Godot 4.4

Launch the main.tscn, you going to be able to create and join a server, in the game if you host the game you can press escape to see your ip and give it to other person to join you

## Current Limitations

- Only the sword weapon is fully functional
- MINIMAL SECURITY : THIS PROTOTYPE IS NOT SECURITY-FOCUSED AND MAY HAVE SIGNIFICANT VULNERABILITIES
