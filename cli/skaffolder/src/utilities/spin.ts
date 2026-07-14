import ora from "ora";

const spinners: any[] = [];
let index = 0;

export default (message: string | boolean) => {
  const spinning = spinners[index] && spinners[index].isSpinning;

  if (message === true) {
    if (spinning) {
      spinners[index].succeed();
    }
    return;
  }

  if (message === false) {
    if (spinning) {
      spinners[index].fail();
    }
    return;
  }

  if (spinning) {
    spinners[index].succeed();
  }

  if (spinners[index]) {
    index++;
  }

  spinners[index] = ora(message).start();
};
