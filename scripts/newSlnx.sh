#!/bin/bash

if [ -z "$1" ]; then
    echo "Использование: $0 <имя_проекта>"
    exit 1
fi

mkdir "$1"
dotnet new console -n "$1" -o "$1"
dotnet new sln -n "$1" -o "$1"
dotnet sln "$1/$1.slnx" add "$1/$1.csproj"
