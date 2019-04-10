//
//  Animator.hpp
//  ClashRoyalHelper
//
//  Created by DOM QIU on 2018/10/16.
//  Copyright © 2018 QiuDong. All rights reserved.
//

#ifndef Animator_hpp
#define Animator_hpp

#include "Animatable.hpp"
#include <MADVPano/AutoRef.h>
#include <list>

typedef void(*ActionCompletionCallback)(void* contextData);

class Animator {
public:
    
    virtual ~Animator() {}
    
    Animator();
    
    inline void setTarget(Animatable* animatable) {_animatable = animatable;}
    
    virtual float update(float dt) = 0;
    
    virtual void start() = 0;
    virtual void stop() = 0;
    
    inline bool isStopped() const {return _isStopped;}
    
protected:
    
    bool _isStopped;
    
    Animatable* _animatable;
};

class RepeatAnimator : public Animator {
public:
    
    virtual ~RepeatAnimator();
    
    RepeatAnimator(AutoRef<Animator> wrappedAction);
    
    virtual void start();
    virtual void start(int loopCount);
    
    virtual void stop();
    
    inline void setLoopCount(int loopCount) {_loopCount = loopCount;}
    
    virtual float update(float dt);
    
private:
    
    int _loopCount;
    
    AutoRef<Animator> _wrappedAction;
};

class AnimatorSequence : public Animator {
public:
    
    virtual ~AnimatorSequence();
    
    AnimatorSequence();
    
    AnimatorSequence& addAction(AutoRef<Animator> action);
    
    virtual void start();
    
    virtual void stop();
    
    virtual float update(float dt);
    
private:
    
    std::list<AutoRef<Animator> > _actions;
    std::list<AutoRef<Animator> >::const_iterator _actionIterator;
};

class AnimatorQueue : public Animator {
public:
    
    virtual ~AnimatorQueue();
    
    AnimatorQueue();
    
    AnimatorQueue& addAction(AutoRef<Animator> action);
    
    virtual void start();
    
    virtual void stop();
    
    void cancelAll();
    
    virtual float update(float dt);
    
private:
    
    std::list<AutoRef<Animator> > _actions;
    std::list<AutoRef<Animator> >::const_iterator _actionIterator;
};

class FiniteAnimator : public Animator {
public:
    
    virtual ~FiniteAnimator() {}
    
    FiniteAnimator();
    
    void setCallback(ActionCompletionCallback* callback, void* callbackContextData);
    
    virtual float update(float dt);
    virtual float doUpdate(float dt, float timeElapsed) = 0;
    
    virtual void start();
    virtual void onStart() = 0;
    
    virtual void stop();
    
protected:
    
    inline void setInterval(float interval) {_interval = interval;}
    
    float _interval;
    
private:
    
    float _timeElapsed;
    
    ActionCompletionCallback* _callback;
    void* _callbackContextData;
};

class MoveToAnimator : public FiniteAnimator {
public:
    
    MoveToAnimator();
    MoveToAnimator(float targetValue);
    
    void setMoveToValue(float targetValue);
    
    inline void setInterval(float interval) {FiniteAnimator::setInterval(interval);}
    
    void onStart();
    
    float doUpdate(float dt, float timeElapsed);
    
protected:
    
    float _targetValue;
    float _startValue;
};

class MoveByAnimator : public FiniteAnimator {
public:
    
    MoveByAnimator();
    MoveByAnimator(float incrementValue);
    
    void setMoveByValue(float incrementValue);
    
    inline void setInterval(float interval) {FiniteAnimator::setInterval(interval);}
    
    void onStart();
    
    float doUpdate(float dt, float timeElapsed);
    
protected:
    
    float _incrementValue;
    float _startValue;
};

class MultiplyByAnimator : public FiniteAnimator {
public:
    
    MultiplyByAnimator();
    MultiplyByAnimator(float augmentValue);
    
    void setMultiplyByValue(float augmentValue);
    
    inline void setInterval(float interval) {FiniteAnimator::setInterval(interval);}
    
    void onStart();
    
    float doUpdate(float dt, float timeElapsed);
    
protected:
    
    float _augmentValue;
    float _startValue;
};

#endif /* Animator_hpp */
