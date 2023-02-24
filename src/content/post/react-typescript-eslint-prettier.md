---
publishDate: 2023-02-22T19:00:00Z
title: Быстро стартуем проект на реакте с линтером
description: Lorem ipsum dolor sit amet
excerpt: Туториал по старту проекта с использованием React + TS + eslint + prettier и соберем все это дело на Vite
image: ~/assets/images/post/react-typescript-eslint-prettier/preview.png
category: Tutorials
tags:
  - react
  - typescript
  - eslint
  - prettier
  - vite
canonical: https://astrowind.vercel.app/react-typescript-eslint-prettier
---

## Инициализация проекта
### При помощи `npm`:
 ```
npm init
 ```
### При помощи `yarn`:
 ```
 yarn init
 ```

## Инициализация TypeScript
 ```
 tsc --init
 ```

## Инициализация eslint
 ```
npx eslint --init
 ```

Ищем файл `.eslintrc.js` и вставляем следующий код:

```js
module.exports = {
    parser: '@typescript-eslint/parser',
    parserOptions: {
        project: 'tsconfig.json',
        tsconfigRootDir : __dirname,
        sourceType: 'module',
    },
    plugins: ['@typescript-eslint/eslint-plugin'],
    extends: [
        'plugin:@typescript-eslint/recommended',
        'plugin:prettier/recommended',
    ],
    root: true,
    env: {
        node: true,
        jest: true,
    },
    ignorePatterns: ['.eslintrc.js'],
    rules: {
        '@typescript-eslint/interface-name-prefix': 'off',
        '@typescript-eslint/explicit-function-return-type': 'off',
        '@typescript-eslint/explicit-module-boundary-types': 'off',
        '@typescript-eslint/no-explicit-any': 'off',
    },
};
```

Далее переустанавливаем зависимости

### При помощи `npm`:
```
 npm install --save-dev typescript tsconfig-paths ts-node ts-loader eslint-plugin-react eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin @types/node
```

### При помощи `yarn`:
```
 yarn add -D typescript tsconfig-paths ts-node ts-loader eslint-plugin-react eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin @types/node
```

## Добавляем prettier
 ```
touch .prettierrc
 ```
Ищем файл `.prettierrc` и вставляем следующий код:

```json
{
  "singleQuote": true,
  "trailingComma": "all"
}
```

Устанавливаем зависимости

### При помощи `npm`:
```
npm install --save-dev prettier eslint-plugin-prettier eslint-config-prettier
```

### При помощи `yarn`:
```
yarn add -D prettier eslint-plugin-prettier eslint-config-prettier
```

## Инициализация React

Устанавливаем зависимости

### При помощи `npm`:

```
    npm install react react-dom
    
    npm install --save-dev @types/react @types/react-dom 
```

### При помощи `yarn`:

```
    yarn add react react-dom
    
    yarn add -D @types/react @types/react-dom 
```

## Дополнение: собираем проект на Vite

### Создаем в корне проекта `index.html`

```
 touch index.html
```

Добавляем в `index.html` контент

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Suit UP !</title>
</head>
<body>
<div id="root"></div>
<script type="module" src="/src/index.tsx"></script>
</body>
</html>
```

### Создаем в корне проекта `src`

```
 touch src
```

### Создаем файлы для инициализации реакта

<sub> опускаемся в src: </sub>

```
 cd src
```

<sub> добавляем типы для Vite: </sub>

```
 touch vite-env.d.ts
```

<sub> вставляем следующий код: </sub>

```
/// <reference types="vite/client" />
```

<sub> создаем файл для инициализации react </sub>

```
 touch index.tsx
```

<sub> вставляем следующий код: </sub>

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './app';
ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

### Создаем в `src` папку `app`, а там файл `index.tsx`

```
cd app
touch index.tsx
```

<sub> вставляем следующий код: </sub>

```tsx
import React, { useState } from 'react';
function App() {
  const [count, setCount] = useState(0);
  return <div>{count}</div>;
}
export default App;
```

### Создаем в корне проекта `.gitignore`

```
 touch .gitignore
```

<sub> вставляем следующий код: </sub>

```
# compiled output
/dist
/node_modules
# Tests
/coverage
/.nyc_output
# IDEs and editors
/.idea
.project
.classpath
.c9/
*.launch
.settings/
*.sublime-workspace
# IDE - VSCode
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
.env
.env.production
```

### Создаем в корне проекта `vite.config.ts`

<sub> устанавливаем заисимости: </sub>

### При помощи `npm`:

```
 npm install --save-dev vite @vitejs/plugin-react
```

### При помощи `yarn`:

```
 yarn add -D vite @vitejs/plugin-react
```

<sub> вставляем следующий код: </sub>

```ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
});
```

```
 touch .gitignore
```

### Структура проекта

```
├── index.html/                      # HTML, определяющий шаблон приложения
├── src/                             # Исходники
│   ├── app/                         # Папка с используемыми элементами
│   │   ├── ...                      # UI-kit для приложения
│   │   └── index.tsx                # Файл экспорта всех компонентов UI-kit
├── .gitignore                       # Список исключённых файлов из Git
├── package.json                     # Список модулей и прочей информации
├── tsconfig.json                    # Список настроек для TypeScript
├── vite.config.ts                   # Конфигурация Vite
├── tsconfig.node.json               # Список настроек для TypeScript для Vite
├── README.md                        # Документация приложения
└── tsconfig.json                    # Параметры компилятора TypeScript
```

### Добавляем скрипты для старта

```
    "dev": "vite --port 3000",
    "build": "tsc && vite build",
    "preview": "vite preview"
```
