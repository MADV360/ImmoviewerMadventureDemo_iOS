//
//  Animatable.hpp
//  ClashRoyalHelper
//
//  Created by DOM QIU on 2018/10/16.
//  Copyright © 2018 QiuDong. All rights reserved.
//

#ifndef Animatable_hpp
#define Animatable_hpp

class Animatable {
public:
    virtual float getCurrentProgress() const = 0;
    
    virtual void setCurrentProgress(float progress) = 0;
};

class AnimationTarget : public Animatable {
public:
    
    AnimationTarget();
    
    AnimationTarget(float initProgress);
    
    float getCurrentProgress() const;
    
    void setCurrentProgress(float progress);
    
private:
    
    float _currentProgress;
};

#endif /* Animatable_hpp */
