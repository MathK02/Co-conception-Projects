function [ code ] = gene_code(n,s)
%% INPUTS : n size of the code
%%          s : number of 1 in the code
%% OUTPUTS :  matrix containing all the combination of codes of size n with s values equal to 1.
%% generation des codes
pos_1=nchoosek(2:n-1,s-2); 

code=zeros(size(pos_1,1),n);
code(:,end)=1;
code(:,1)=1;

for j=1:size(pos_1,1)
    code(j,pos_1(j,:))=1;
   
end
    

code=code';
