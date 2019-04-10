//
//  Animatable.cpp
//  ClashRoyalHelper
//
//  Created by DOM QIU on 2018/10/16.
//  Copyright © 2018 QiuDong. All rights reserved.
//
#ifdef TARGET_OS_IOS
#include "Animatable.hpp"

AnimationTarget::AnimationTarget(float initProgress) {
    _currentProgress = initProgress;
}

AnimationTarget::AnimationTarget()
: AnimationTarget(0.f)
{
}

float AnimationTarget::getCurrentProgress() const {
    return _currentProgress;
}

void AnimationTarget::setCurrentProgress(float progress) {
    _currentProgress = progress;
}
#endif //#ifdef TARGET_OS_IOS