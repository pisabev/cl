part of chart;

class EasingEngine {

    static num linear(num time, num duration, num change, num baseValue) {
        return change * time / duration + baseValue;
    }

    static num easeInQuad(num time, num duration, num change, num baseValue) {
        time = time / duration;
        return change * time * time + baseValue;
    }

    static num easeOutQuad(num time, num duration, num change, num baseValue) {
        time = time / duration;
        return -change * time * (time - 2) + baseValue;
    }

    static num easeInOutQuad(num time, num duration, num change, num baseValue) {
        time = time / (duration / 2);
        if (time < 1)
            return change / 2 * time * time + baseValue;
        time--;
        return -change / 2 * (time * (time - 2) - 1) + baseValue;
    }

    static num easeInCubic(num time, num duration, num change, num baseValue) {
        time = time / duration;
        return change * time * time * time + baseValue;
    }

    static num easeOutCubic(num time, num duration, num change, num baseValue) {
        time = time / duration;
        time--;
        return change * (time * time * time + 1) + baseValue;
    }

    static num easeInOutCubic(num time, num duration, num change, num baseValue) {
        time = time / (duration / 2);
        if (time < 1)
            return change / 2 * time * time * time + baseValue;
        time -= 2;
        return change / 2 * (time * time * time + 2) + baseValue;
    }

    static num easeInQuartic(num time, num duration, num change, num baseValue) {
        time = time / duration;
        return change * time * time * time * time + baseValue;
    }

    static num easeOutQuartic(num time, num duration, num change, num baseValue) {
        time = time / duration;
        time--;
        return -change * (time * time * time * time - 1) + baseValue;
    }

    static num easeInOutQuartic(num time, num duration, num change, num baseValue) {
        time = time / (duration / 2);
        if (time < 1)
            return change / 2 * time * time * time * time + baseValue;
        time -= 2;
        return -change / 2 * (time * time * time * time - 2) + baseValue;
    }

    static num easeInQuintic(num time, num duration, num change, num baseValue) {
        time = time / duration;
        return change * time * time * time * time * time + baseValue;
    }

    static num easeOutQuintic(num time, num duration, num change, num baseValue) {
        time = time / duration;
        time--;
        return change * (time * time * time * time * time + 1) + baseValue;
    }

    static num easeInOutQuintic(num time, num duration, num change, num baseValue) {
        time = time / (duration / 2);
        if (time < 1)
            return change / 2 * time * time * time * time * time + baseValue;
        time -= 2;
        return change / 2 * (time * time * time * time * time + 2) + baseValue;
    }

    static num easeInSine(num time, num duration, num change, num baseValue) {
        return -change * cos(time / duration * (PI / 2)) + change + baseValue;
    }

    static num easeOutSine(num time, num duration, num change, num baseValue) {
        return change * sin(time / duration * (PI / 2)) + baseValue;
    }

    static num easeInOutSine(num time, num duration, num change, num baseValue) {
        return -change / 2 * (cos(time / duration * PI) - 1) + baseValue;
    }

    static num easeInExponential(num time, num duration, num change, num baseValue) {
        return change * pow(2, 10 * (time / duration - 1)) + baseValue;
    }

    static num easeOutExponential(num time, num duration, num change, num baseValue) {
        return change * (-pow(2, -10 * time / duration) + 1) + baseValue;
    }

    static num easeInOutExponential(num time, num duration, num change, num baseValue) {
        time = time / (duration / 2);
        if (time < 1)
            return change / 2 * pow(2, 10 * (time - 1)) + baseValue;
        time--;
        return change / 2 * (-pow(2, -10 * time) + 2) + baseValue;
    }

    static num easeInCircular(num time, num duration, num change, num baseValue) {
        time = time / duration;
        return -change * (sqrt(1 - time * time) - 1) + baseValue;
    }

    static num easeOutCircular(num time, num duration, num change, num baseValue) {
        time = time / duration;
        time--;
        return change * sqrt(1 - time * time) + baseValue;
    }

    static num easeInOutCircular(num time, num duration, num change, num baseValue) {
        time = time / (duration / 2);
        if (time < 1)
            return -change / 2 * sqrt(1 - time * time) + baseValue;
        time -= 2;
        return change / 2 * (sqrt(1 - time * time) + 1) + baseValue;
    }
}