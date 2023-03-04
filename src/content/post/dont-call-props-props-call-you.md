---
publishDate: 2023-03-04T23:00:00Z
title: Не вызывай пропсы, пропсы вызовут тебя
description: Один из подходов для работы с пропсами
excerpt: Туториал по созданию собственных компонентов с другим подходом
image: ~/assets/images/post/dont-call-props-props-call-you/preview.png
category: Tutorials
tags:
  - react
  - typescript
  - Inversion of control
  - UI kit
  - DI
  - HOC
canonical: https://groshidze.tech/dont-call-props-props-call-you
---

## О чём это статья ?
 
На одном из проектов мне прилетела задача по созданию степера для ui kit'а на проекте, казалось бы все достаточно просто, создаешь компонент
обертки и компонент для каждого отдельно степа. Я начал смотреть как это реализовано в material ui https://mui.com/material-ui/react-stepper/,

```tsx
import * as React from 'react';
import Box from '@mui/material/Box';
import Stepper from '@mui/material/Stepper';
import Step from '@mui/material/Step';
import StepLabel from '@mui/material/StepLabel';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';

const steps = ['Select campaign settings', 'Create an ad group', 'Create an ad'];

export default function HorizontalLinearStepper() {
  const [activeStep, setActiveStep] = React.useState(0);
  const [skipped, setSkipped] = React.useState(new Set<number>());

  const isStepOptional = (step: number) => {
    return step === 1;
  };

  const isStepSkipped = (step: number) => {
    return skipped.has(step);
  };

  const handleNext = () => {
    let newSkipped = skipped;
    if (isStepSkipped(activeStep)) {
      newSkipped = new Set(newSkipped.values());
      newSkipped.delete(activeStep);
    }

    setActiveStep((prevActiveStep) => prevActiveStep + 1);
    setSkipped(newSkipped);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleSkip = () => {
    if (!isStepOptional(activeStep)) {
      // You probably want to guard against something like this,
      // it should never occur unless someone's actively trying to break something.
      throw new Error("You can't skip a step that isn't optional.");
    }

    setActiveStep((prevActiveStep) => prevActiveStep + 1);
    setSkipped((prevSkipped) => {
      const newSkipped = new Set(prevSkipped.values());
      newSkipped.add(activeStep);
      return newSkipped;
    });
  };

  const handleReset = () => {
    setActiveStep(0);
  };

  return (
    <Box sx={{ width: '100%' }}>
      <Stepper activeStep={activeStep}>
        {steps.map((label, index) => {
          const stepProps: { completed?: boolean } = {};
          const labelProps: {
            optional?: React.ReactNode;
          } = {};
          if (isStepOptional(index)) {
            labelProps.optional = (
              <Typography variant="caption">Optional</Typography>
            );
          }
          if (isStepSkipped(index)) {
            stepProps.completed = false;
          }
          return (
            <Step key={label} {...stepProps}>
              <StepLabel {...labelProps}>{label}</StepLabel>
            </Step>
          );
        })}
      </Stepper>
      {activeStep === steps.length ? (
        <React.Fragment>
          <Typography sx={{ mt: 2, mb: 1 }}>
            All steps completed - you&apos;re finished
          </Typography>
          <Box sx={{ display: 'flex', flexDirection: 'row', pt: 2 }}>
            <Box sx={{ flex: '1 1 auto' }} />
            <Button onClick={handleReset}>Reset</Button>
          </Box>
        </React.Fragment>
      ) : (
        <React.Fragment>
          <Typography sx={{ mt: 2, mb: 1 }}>Step {activeStep + 1}</Typography>
          <Box sx={{ display: 'flex', flexDirection: 'row', pt: 2 }}>
            <Button
              color="inherit"
              disabled={activeStep === 0}
              onClick={handleBack}
              sx={{ mr: 1 }}
            >
              Back
            </Button>
            <Box sx={{ flex: '1 1 auto' }} />
            {isStepOptional(activeStep) && (
              <Button color="inherit" onClick={handleSkip} sx={{ mr: 1 }}>
                Skip
              </Button>
            )}
            <Button onClick={handleNext}>
              {activeStep === steps.length - 1 ? 'Finish' : 'Next'}
            </Button>
          </Box>
        </React.Fragment>
      )}
    </Box>
  );
}
```

![вид компонента](/dont-call-props-props-call-you/steper-example.png)

Не кажется ли вам, что слишком много кода для такого простого компонента. По-факту я хочу обернуть все степы в контейнер
и он сам под капотом должен понимать какой компонент уже пройден, а какой сейчас активен. Плюс есть еще одна штука: все степы мы прокидываем через массив,
а я еще хочу управлять этим через компоненты, то есть вручную прокидывать каждый степ.

### Я хочу видеть свой компонент примерно в таком виде
```tsx
import React, { useState } from 'react';

const Component = () => {
	const [activeStep, setActiveStep] = useState<number>(0);

	const handleSelect = (step: number) => {
		setActiveStep(step);
	};

	const checkValid = (step: number, index: number) => {
		return true;
	};
	
	return (
			<Steps
              isValid={checkValid}
              color="blue"
              onSelect={handleSelect}
              isColumn
              activeStep={activeStep}
            >
				<Steps.Step>1 шаг</Steps.Step>
				<Steps.Step>2 шаг</Steps.Step>
				<Steps.Step>3 шаг</Steps.Step>
				<Steps.Step>4 шаг</Steps.Step>
				<Steps.Step>5 шаг</Steps.Step>
			</Steps>
    );
};
```

Вообщем тим-лид попросил сделать именно так и подсказал, что можно копать в сторону верхнеуровнего API React ([React Top-Level API](https://reactjs.org/docs/react-api.html)).

## React Top-Level API

Из того что мне пригодится это работа с Children и cloneElement

## Создание

Я начал создавать контейнер, на первом этапе он выглядел примерно так:

```tsx
import React, {
	Children,
	cloneElement,
	FC,
	ReactElement,
	PropsWithChildren,
} from 'react';
import { isFunction, assign, map } from 'lodash';

import { StepsContext } from './Steps.context';
import { DefaultColor, DefaultColumn } from './Steps.types';

import Step from './Step';

import './Steps.scss';

interface IStepsProps {
	color: BaseColors;
	isColumn: boolean;
	nonLinear?: boolean;
	activeStep: number;
	isValid?: (step: number, index: number) => boolean;
	onSelect?: (step: number) => void;
}

const Steps: FC<PropsWithChildren<IStepsProps>> = ({
	color,
	isColumn,
	nonLinear,
	isValid,
	activeStep,
	onSelect,
	children,
}) => {
	const steps = Children.toArray(children);
	const { length } = steps;

	const render = () => {
		return map(steps, (step, index) => {
			const isFirst = index === 0;
			const isLast = index === length - 1;
			const isActive = activeStep === index;
			const isCompleted = !nonLinear && activeStep > index;
			const isValidStep = isFunction(isValid) ? isValid(activeStep, index) : true;

			const StepContext = (
				<StepsContext.Provider
					key={index}
					value={{
						isFirst,
						isLast,
						isActive,
						isCompleted,
						isValid: isValidStep,
						index,
						onSelect,
						color,
						isColumn,
				}}
				>
					{step}
				</StepsContext.Provider>
			);

			return cloneElement(StepContext as ReactElement);
		});
	};

	return (
		<div className="steps" role="menubar">
			<div className="steps__container">
				<ol className="list">{render()}</ol>
			</div>
		</div>
	);
};

Steps.displayName = 'Steps';
Steps.defaultProps = {
	color: DefaultColor,
	isColumn: DefaultColumn,
	nonLinear: false,
};

export default assign(Steps, { Step });

```

Сейчас будем разбираться что здесь происходит:

### Создаем массив степов из передаваемых children

```tsx
const steps = Children.toArray(children);
const { length } = steps;
```

Переменная `steps` нужна, для того чтобы сохранить наши степы, которые мы передаем как `children`

```tsx
<Steps>
	<Steps.Step>1 шаг</Steps.Step>
	<Steps.Step>2 шаг</Steps.Step>
	<Steps.Step>3 шаг</Steps.Step>
	<Steps.Step>4 шаг</Steps.Step>
	<Steps.Step>5 шаг</Steps.Step>
</Steps>
```

т.е. все степы которые мы передали в компонент `Steps` будут храниться в переменной `steps` в виде массива объектов

### Создаем метод render для рендеринга всех шагов через cloneElement

```tsx
const render = () => {
		return map(steps, (step, index) => {
			const isFirst = index === 0; // нужен для понимания является ли элемент первым
			const isLast = index === length - 1; // нужен для понимания является ли элемент последним
			const isActive = activeStep === index; // проверка на активный степ
			const isCompleted = !nonLinear && activeStep > index; // проверка на пройденный степ
			const isValidStep = isFunction(isValid) ? isValid(activeStep, index) : true; // нужен для валидации степов, если это важно, по дефолту true

			const StepContext = (
				<StepsContext.Provider
					key={index}
					value={{
						isFirst,
						isLast,
						isActive,
						isCompleted,
						isValid: isValidStep,
						index,
						onSelect,
						color,
						isColumn,
				}}
				>
					{step}
				</StepsContext.Provider>
			); // создаем контекст для отдельного степа, чтобы прокинуть в него данные, это нужно чтобы не прокидывать данные в каждый отдельный степ

			return cloneElement(StepContext as ReactElement); // клонирем элемент со прокинутым контекстом
		});
	};
```

Наверное самая интересная часть метода render - это создание контекста, давайте посмотрим, что такое `StepsContext`

```tsx
import { createContext } from 'react';

export interface IStepsContextProps {
	index: number;
	isFirst: boolean;
	isLast: boolean;
	isActive: boolean;
	isCompleted: boolean;
	isValid: boolean;
	onSelect?: (step: number) => void;
	isColumn: boolean;
	color: BaseColors;
}

export const StepsContext = createContext({} as IStepsContextProps);
```

Мы создаем изолированный контекст, чтобы каждый отдельный Step имел свои индивидуальные пропсы отличающиеся от других степов
также мы сразу прокидываем объект и описываем типы для контекста, чтобы provider понимал какие props он будет получать в render()

### Что из себя представляет компонент Step

```tsx
import React, { FC, PropsWithChildren, useContext } from 'react';
import { isFunction } from 'lodash';

import { DefaultColor } from './Steps.types';
import { StepsContext, IStepsContextProps } from './Steps.context';

import './Step.scss';

const Step: FC<PropsWithChildren> = ({ children }) => {
	const {
		isFirst,
		isLast,
		isActive,
		isCompleted,
		isValid,
		onSelect,
		index,
		isColumn,
		color,
	} =	useContext<IStepsContextProps>(StepsContext); // получаем данные которые передали в Provider в render()
	const classNameColor = `step-color-${color}`;
	const isDefaultBgColor = isActive || isCompleted ? classNameColor : '';

	const handleChange = () => {
		if (!isActive && isFunction(onSelect)) onSelect(index);
	};

	return (
		<li className="step">
			{isValid ? (
				<div className={`step__valid ${isColumn ? 'column' : 'row'}`}>
					<button
						tabIndex={0}
						onClick={handleChange}
						className={`round ${isDefaultBgColor}`}
					>
						{isCompleted ? (
							<img
								src="https://api.iconify.design/material-symbols:check-small.svg?color=white"
								alt="check"
							/>
						) : (
							<span>{index + 1}</span>
						)}
					</button>
					<span
						role="button"
						tabIndex={0}
						aria-hidden="true"
						onClick={handleChange}
					>
            {children}
					</span>
				</div>
			) : (
				<div className="step__invalid">
					{isFirst || isLast ? 'styles.errorImage ' : 'styles.errorImageCustom'}
				</div>
			)}
		</li>
	);
};

Step.displayName = 'Step';

export default Step;
```
 
Здесь все просто, самый обычный Step со стилями, чтобы было красиво)

Предварительный результат
![вид компонента](/dont-call-props-props-call-you/steper-example2.png)
![вид компонента](/dont-call-props-props-call-you/steper-example3.png)

### Но есть нюанс !

Каждый раз, когда мы переключаем степ, кликаем на него или приключаем через кнопки, то происходит перерендер всех степов.
![вид компонента](/dont-call-props-props-call-you/console.png)
![вид компонента](/dont-call-props-props-call-you/console2.png)

В чем проблема, такой подход для создания компонент можно использовать для MultiSelect и Autocomplete,
там может быть достаточно много компонентов и перерендоривать каждый из них, будет достаточно трудозатратно

### Как это решить ?

Нужно начать все это оптимизировать ! 

useMemo, useCallback, memo это все что нам нужно.

### Переписываем метод render
```tsx
const render = () => {
		return Children.map(children, (child, index) => {
			const isFirst = index === 0;
			const isLast = index === length - 1;
			const isActive = activeStep === index;
			const isCompleted = !nonLinear && activeStep > index;
			const isValidStep = isFunction(isValid) ? isValid(activeStep, index) : true;

			return cloneElement(child as React.ReactElement, {
				isFirst,
				isLast,
				isActive,
				isCompleted,
				isValid: isValidStep,
				index,
				onSelect,
				color,
				isColumn,
			});
		});
	};
```

Сразу замечаем, что мы избавились контекста. Это было нужно, чтобы правильно использовать memo, так как 
каждый раз когда мы оборачиваем компонент в провайдер и прокидываем туда пропсы, то у нас создается новые ссылка на эти пропсы,
если просто копировать элементы через Children.map и обернув компонент Step в memo, у нас будут перерисовываться, только те компоненты,
которые реально поменяли пропсы.

### Переписываем Step

```tsx
import React, { FC, memo, PropsWithChildren } from 'react';
import { isFunction } from 'lodash';

const Step: FC<PropsWithChildren<IStepProps>> = (props) => {
	const {
		isFirst,
		isLast,
		isActive,
		isCompleted,
		isValid,
		onSelect,
		index,
		isColumn,
		color,
		children,
	} =	props;
	const classNameColor = `step-color-${color}`;
	const isDefaultBgColor = isActive || isCompleted ? classNameColor : '';

	const handleChange = () => {
		if (!isActive && isFunction(onSelect)) onSelect(index);
	};

	return (
		<li className="step">
			{isValid ? (
				<div className={`step__valid ${isColumn ? 'column' : 'row'}`}>
					<button
						tabIndex={0}
						onClick={handleChange}
						className={`round ${isDefaultBgColor}`}
					>
						{isCompleted ? (
							<img
								src="https://api.iconify.design/material-symbols:check-small.svg?color=white"
								alt="check"
							/>
						) : (
							<span>{index + 1}</span>
						)}
					</button>
					<span
						role="button"
						tabIndex={0}
						aria-hidden="true"
						onClick={handleChange}
					>
             {children}
					</span>
				</div>
			) : (
				<div className="step__invalid">
					{isFirst || isLast ? 'styles.errorImage ' : 'styles.errorImageCustom'}
				</div>
			)}
		</li>
	);
};

const StepContainer = memo(Step);
```

Мы видим, что так как мы избавились от useContext, то нам пришлось принимать все данные через props.
Тут встает следующий вопрос, а как все это типизировать ?
Главная проблема, что когда мы будем использовать компонент `Step` TS будет просить нас прокинуть props, а нам это не нужно, 
так как мы это уже сделали в методе `render`.

И тут на ум сразу приходит HOC connect из react-redux. Там тоже можно прокидывать два типа пропсов,
те которые лежат в `mapStateToProps` и `mapDispatchToProps` и те которые мы хоти прокинуть вручную.

### Пишем свой HOC

```tsx
import React, { ComponentType, FC } from 'react';

export const HOC = <TInjectedProps, TOwnProps>(injectedProps: TInjectedProps) => {
	const withHoc = (Component: ComponentType<TInjectedProps & TOwnProps>): FC<TOwnProps> => {
		const WithPureLayout: FC<TOwnProps> = (props) => (
			<Component {...injectedProps} {...props} />
		);

		WithPureLayout.displayName = `WithPureLayout(${
			Component?.displayName ?? Component?.name
		})`;

		return WithPureLayout;
	};

	return withHoc;
};
```

Наконец-то пригодилось знание замыкания, не зря его спрашивают)

Если кратко, то у нас есть HOC, который принимает дефолтные пропсы и компонет. Сначала он будет получать пропсы тип TInjectedProps,
из названия понимаем, что это как раз таки те самые пропсы, которые мы прокидываем автоматически.
Далее мы возвращаем первое замыкание, которое принимает компонент, принимающий в себя props типа TInjectedProps & TOwnProps,
по факту мы их просто объединяем и говорим о том, что компонент работает со всеми этими пропсами.
Ну и самой главной строчкой кода для нас является `: FC<TOwnProps>`, именно она нам позволяет не ожидать дефолтных пропсов при вызове `Step`.

Вот так теперь выглядит export Step`а

```tsx
import React, { FC, memo, PropsWithChildren } from 'react';
import { isFunction } from 'lodash';

import { HOC } from '../hoc';

import './Step.scss';

import { IStepProps } from './Steps';

const Step: FC<PropsWithChildren<IStepProps>> = (props) => {
	const {
		isFirst,
		isLast,
		isActive,
		isCompleted,
		isValid,
		onSelect,
		index,
		isColumn,
		color,
		children,
	} =	props;
	const classNameColor = `step-color-${color}`;
	const isDefaultBgColor = isActive || isCompleted ? classNameColor : '';

	const handleChange = () => {
		if (!isActive && isFunction(onSelect)) onSelect(index);
	};

	return (
		<li className="step">
			{isValid ? (
				<div className={`step__valid ${isColumn ? 'column' : 'row'}`}>
					<button
						tabIndex={0}
						onClick={handleChange}
						className={`round ${isDefaultBgColor}`}
					>
						{isCompleted ? (
							<img
								src="https://api.iconify.design/material-symbols:check-small.svg?color=white"
								alt="check"
							/>
						) : (
							<span>{index + 1}</span>
						)}
					</button>
					<span
						role="button"
						tabIndex={0}
						aria-hidden="true"
						onClick={handleChange}
					>
             {children}
					</span>
				</div>
			) : (
				<div className="step__invalid">
					{isFirst || isLast ? 'styles.errorImage ' : 'styles.errorImageCustom'}
				</div>
			)}
		</li>
	);
};

const StepContainer = memo(Step);

Step.displayName = 'Step';

export default HOC<IStepProps, PropsWithChildren>({} as IStepProps)(StepContainer);
```

### Использование

```tsx
import React, { useState, useCallback } from 'react';
const Component = () => {
	const [activeStep, setActiveStep] = useState<number>(0);

	const handleSelect = useCallback((step: number) => {
		setActiveStep(step);
	}, []);

	const checkValid = (step: number, index: number) => {
		return true;
	};
	
	return (
			<Steps isValid={checkValid} color="blue" onSelect={handleSelect} isColumn activeStep={activeStep}>
				<Steps.Step>1 шаг</Steps.Step>
				<Steps.Step>2 шаг</Steps.Step>
				<Steps.Step>3 шаг</Steps.Step>
				<Steps.Step>4 шаг</Steps.Step>
				<Steps.Step>5 шаг</Steps.Step>
			</Steps>
    );
}
```

### Заключение

В последнее время читаю про подход Inversion of Control (IoS) и про частный паттерн этого подхода как Dependency Injection, и честно говоря,
пока очень тяжело говорить, о том, что я умею из использовать или вообще понимаю как этим пользоваться, наверное именно поэтому не стал называть статью как-то пафосно типа: "Используем DI в React".
Но в общем и целом мне показалось, что по крайней мере пример с useContext, а особенно когда используется Provider для контекста - это место, которое очень похоже на DI, но опять же я могу очень сильно ошибаться, буду рад если вы напишите в личку обратную связь и мысли по поводу всего этого туториала.
А так буду рад, если вам понравился такой подход к созданию компонент или если он поможет решить вам какую-то задачу на проекте.

Готовый код можете посмотреть [здесь](https://github.com/DmitriyGrosh/react-mobx-starter/tree/develop/src/shared/ui/steps)
