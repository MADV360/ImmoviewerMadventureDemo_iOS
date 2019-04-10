//
//  Animator.cpp
//  ClashRoyalHelper
//
//  Created by DOM QIU on 2018/10/16.
//  Copyright © 2018 QiuDong. All rights reserved.
//
#ifdef TARGET_OS_IOS
#include "Animator.hpp"

using namespace std;

#pragma mark    Animator

Animator::Animator()
: _animatable(NULL)
, _isStopped(true)
{
}

#pragma mark    RepeatAnimator

RepeatAnimator::~RepeatAnimator() {
    _wrappedAction = NULL;
}

RepeatAnimator::RepeatAnimator(AutoRef<Animator> wrappedAction)
: _wrappedAction(wrappedAction)
, _loopCount(-1)
{
    
}

void RepeatAnimator::start() {
    start(_loopCount);
}

void RepeatAnimator::start(int loopCount) {
    if (_wrappedAction == NULL) return;
    _loopCount = loopCount;
    _wrappedAction->setTarget(_animatable);
    _wrappedAction->start();
    _isStopped = false;
    
    update(0.f);
}

void RepeatAnimator::stop() {
    if (_wrappedAction == NULL) return;
    _isStopped = true;
    _wrappedAction->stop();
}

float RepeatAnimator::update(float dt) {
    if (_wrappedAction == NULL) return 0.f;
    if (_isStopped) return 0.f;
    float timeToConsume = dt;
    while (!_isStopped)
    {
        float timeConsumed = _wrappedAction->update(timeToConsume);
        if (timeConsumed < timeToConsume || _wrappedAction->isStopped())
        {
            if (_loopCount < 0 || --_loopCount > 0)
            {
                _wrappedAction->stop();
                _wrappedAction->start();
            }
            else
            {
                stop();
            }
        }
        timeToConsume -= timeConsumed;
        if (timeToConsume <= 0.f)
            break;
    }
    return dt - timeToConsume;
}

#pragma mark    AnimatorSequence

AnimatorSequence::~AnimatorSequence() {
    _actions.clear();
}

AnimatorSequence::AnimatorSequence() {
    _actionIterator = _actions.end();
}

AnimatorSequence& AnimatorSequence::addAction(AutoRef<Animator> action) {
    _actions.push_back(action);
    return *this;
}

void AnimatorSequence::start() {
    if (_actions.size() <= 0) return;
    _actionIterator = _actions.begin();
    AutoRef<Animator> action = *_actionIterator;
    if (NULL != action)
    {
        action->setTarget(_animatable);
        action->start();
    }
    _isStopped = false;
    
    update(0.f);
}

void AnimatorSequence::stop() {
    if (_actionIterator != _actions.end())
    {
        AutoRef<Animator> action = *_actionIterator;
        if (NULL != action) action->stop();
        _actionIterator = _actions.end();
    }
    _isStopped = true;
}

float AnimatorSequence::update(float dt) {
    if (_isStopped) return 0.f;
    if (_actions.size() <= 0) return 0.f;
    AutoRef<Animator> action = *_actionIterator;
    
    float timeToConsume = dt;
    while (_actionIterator != _actions.end())
    {
        if (NULL == action)
        {
            _actionIterator++;
            if (_actionIterator != _actions.end())
            {
                action = *_actionIterator;
            }
            if (NULL != action)
            {
                action->setTarget(_animatable);
                action->start();
            }
        }
        else
        {
            float timeConsumed = action->update(timeToConsume);
            if (timeConsumed < timeToConsume || action->isStopped())
            {
                action->stop();
                action = NULL;
                
                _actionIterator++;
                if (_actionIterator != _actions.end())
                {
                    action = *_actionIterator;
                }
                if (NULL != action)
                {
                    action->setTarget(_animatable);
                    action->start();
                }
            }
            timeToConsume -= timeConsumed;
            if (timeToConsume <= 0.f)
                break;
        }
    }
    if (_actionIterator == _actions.end())
    {
        stop();
    }
    return dt - timeToConsume;
}

#pragma mark    AnimatorQueue

AnimatorQueue::~AnimatorQueue() {
    cancelAll();
}

AnimatorQueue::AnimatorQueue() {
    _actionIterator = _actions.end();
}

AnimatorQueue& AnimatorQueue::addAction(AutoRef<Animator> action) {
    _actions.push_back(action);
    return *this;
}

void AnimatorQueue::start() {
    if (_actions.size() <= 0) return;
    if (_actionIterator == _actions.end())
    {
        _actionIterator = _actions.begin();
    }
    AutoRef<Animator> action = *_actionIterator;
    if (NULL != action)
    {
        action->setTarget(_animatable);
        if (action->isStopped())
        {
            action->start();
        }
    }
    _isStopped = false;
    
    update(0.f);
}

void AnimatorQueue::stop() {
    _isStopped = true;
}

void AnimatorQueue::cancelAll() {
    if (_actionIterator != _actions.end())
    {
        AutoRef<Animator> action = *_actionIterator;
        if (NULL != action) action->stop();
    }
    _actions.clear();
    _actionIterator = _actions.end();
    _isStopped = true;
}

float AnimatorQueue::update(float dt) {
    if (_isStopped) return 0.f;
    if (_actions.size() <= 0) return 0.f;
    AutoRef<Animator> action = *_actionIterator;
    
    float timeToConsume = dt;
    while (_actionIterator != _actions.end())
    {
        if (NULL == action)
        {
            std::list<AutoRef<Animator> >::const_iterator tmpIter = _actionIterator;
            _actionIterator++;
            _actions.erase(tmpIter);
            if (_actionIterator != _actions.end())
            {
                action = *_actionIterator;
            }
            if (NULL != action)
            {
                action->setTarget(_animatable);
                action->start();
            }
        }
        else
        {
            float timeConsumed = action->update(timeToConsume);
            if (timeConsumed < timeToConsume || action->isStopped())
            {
                action->stop();
                action = NULL;
                
                std::list<AutoRef<Animator> >::const_iterator tmpIter = _actionIterator;
                _actionIterator++;
                _actions.erase(tmpIter);
                if (_actionIterator != _actions.end())
                {
                    action = *_actionIterator;
                }
                if (NULL != action)
                {
                    action->setTarget(_animatable);
                    action->start();
                }
            }
            timeToConsume -= timeConsumed;
            if (timeToConsume <= 0.f)
                break;
        }
    }
    if (_actionIterator == _actions.end())
    {
        stop();
    }
    return dt - timeToConsume;
}

#pragma mark    FiniteAnimator

FiniteAnimator::FiniteAnimator()
: _callback(NULL)
, _callbackContextData(NULL)
, _interval(0.f)
, _timeElapsed(0.f)
{
}

void FiniteAnimator::setCallback(ActionCompletionCallback* callback, void* callbackContextData) {
    _callback = callback;
    _callbackContextData = callbackContextData;
}

float FiniteAnimator::update(float dt) {
    if (_isStopped) return 0.f;
    float ret = dt;
    //    printf("FiniteLinearAnimator::update : dt=%f, _timeElapsed/_interval=%f/%f, _startValue/currentValue/_targetValue=%f/%f/%f", dt, _timeElapsed, _interval, _startValue, _animatable.getCurrentValue(), _targetValue);///!!!For Debug
    _timeElapsed += dt;
    if (_timeElapsed >= _interval)
    {
        dt = dt - _timeElapsed + _interval;
        _timeElapsed = _interval;
        ret = doUpdate(dt, _interval);
        stop();
    }
    else
    {
        ret = doUpdate(dt, _timeElapsed);
        if (ret < dt)
        {
            stop();
        }
    }
    return ret;
}

void FiniteAnimator::start() {
    _isStopped = false;
    _timeElapsed = 0.f;
    onStart();
    
    update(0.f);
}

void FiniteAnimator::stop() {
    _isStopped = true;
    if (_callback)
    {
        (*_callback)(_callbackContextData);
    }
}

#pragma mark    MoveToAnimator

MoveToAnimator::MoveToAnimator(float targetValue)
: _targetValue(targetValue)
{
    
}

MoveToAnimator::MoveToAnimator()
{
    
}

void MoveToAnimator::setMoveToValue(float targetValue) {
    _targetValue = targetValue;
}

void MoveToAnimator::onStart() {
    if (!_animatable) return;
    _startValue = _animatable->getCurrentProgress();
}

float MoveToAnimator::doUpdate(float dt, float timeElapsed) {
    if (!_animatable) return 0.f;
    if (timeElapsed >= _interval)
    {
        _animatable->setCurrentProgress(_targetValue);
    }
    else
    {
        _animatable->setCurrentProgress((_startValue * (_interval - timeElapsed) + _targetValue * timeElapsed) / _interval);
    }
    return dt;
}

#pragma mark    MoveByAnimator

MoveByAnimator::MoveByAnimator(float incrementValue)
: _incrementValue(incrementValue)
{
    
}

MoveByAnimator::MoveByAnimator()
{
    
}

void MoveByAnimator::setMoveByValue(float incrementValue) {
    _incrementValue = incrementValue;
}

void MoveByAnimator::onStart() {
    if (!_animatable) return;
    _startValue = _animatable->getCurrentProgress();
}

float MoveByAnimator::doUpdate(float dt, float timeElapsed) {
    if (!_animatable) return 0.f;
    if (timeElapsed >= _interval)
    {
        _animatable->setCurrentProgress(_startValue + _incrementValue);
    }
    else
    {
        _animatable->setCurrentProgress((_startValue * (_interval - timeElapsed) + (_startValue + _incrementValue) * timeElapsed) / _interval);
    }
    return dt;
}

#pragma mark    MultiplyByAnimator

MultiplyByAnimator::MultiplyByAnimator(float augmentValue)
: _augmentValue(augmentValue)
{
    
}

MultiplyByAnimator::MultiplyByAnimator()
: _augmentValue(1.f)
{
    
}

void MultiplyByAnimator::setMultiplyByValue(float augmentValue) {
    _augmentValue = augmentValue;
}

void MultiplyByAnimator::onStart() {
    if (!_animatable) return;
    _startValue = _animatable->getCurrentProgress();
}

float MultiplyByAnimator::doUpdate(float dt, float timeElapsed) {
    if (!_animatable) return 0.f;
    if (timeElapsed >= _interval)
    {
        _animatable->setCurrentProgress(_startValue * _augmentValue);
    }
    else
    {
        _animatable->setCurrentProgress(_startValue * (_interval - timeElapsed + _augmentValue * timeElapsed) / _interval);
    }
    return dt;
}

#endif //#ifdef TARGET_OS_IOS
